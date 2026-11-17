import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	property bool isDeleting: false

	signal actionTriggered(string action)

	readonly property int popupWidth: Theme.roundScaled(620, root.sf)
	readonly property int popupHeight: Theme.roundScaled(430, root.sf)

	function clamp(v, min, max) {
		return Theme.clamp(v, min, max);
	}

	// ---- cliphist helpers (molde: Services/LauncherService.qml + minflair Clipboard.qml) ----

	function decodeId(itemId) {
		if (!itemId)
			return "";
		return itemId;
	}

	function copyItem(itemId) {
		if (!itemId)
			return;
		copyProcess.command = ["cliphist", "decode", itemId];
		copyProcess.stdout = copyOutput;
		copyProcess.onFinished = null;
		copyProcess.running = true;
	}

	function copyItemDetached(itemId) {
		if (!itemId)
			return;
		Quickshell.execDetached(["bash", "-c", "cliphist decode " + itemId + " | wl-copy"]);
	}

	function lineToShellSafe(s) {
		if (!s) return "";
		return "'" + s.replaceAll("'", "'\''") + "'";
	}
	function deleteItem(index, fullLine) {
		root.isDeleting = true;
		deletingResetTimer.restart();
		filteredModel.remove(index, 1, clipboardModel);
		Quickshell.execDetached(["bash", "-c", "echo " + lineToShellSafe(fullLine) + " | cliphist delete"]);
	}

	function wipeClipboard() {
		if (filteredModel.count === 0)
			return;
		root.isDeleting = true;
		wipeTimer.restart();
		filteredModel.clear();
		Quickshell.execDetached(["cliphist", "wipe"]);
	}

	function loadClipboard() {
		clipboardModel.clear();
		filteredModel.clear();
		clipboardProcess.running = true;
	}

	function filterClipboard(query) {
		let q = (query || "").trim().toLowerCase();
		filteredModel.clear();
		for (let i = 0; i < clipboardModel.count; i++) {
			const entry = clipboardModel.get(i);
			const hay = (entry.text + " " + (entry.preview || "")).toLowerCase();
			if (!q || hay.includes(q))
				filteredModel.append(entry);
		}
		if (filteredModel.count > 0)
			resultList.currentIndex = 0;
		else
			resultList.currentIndex = -1;
	}

	ListModel {
		id: clipboardModel
	}

	ListModel {
		id: filteredModel
	}

	// ---- processos (molde: LauncherService clipProcess/decodeProc) ----

	Process {
		id: clipboardProcess

		command: ["cliphist", "list"]
		stdout: StdioCollector {
			id: clipboardOutput
			waitForEnd: true
		}
		onExited: function(exitCode) {
			if (exitCode !== 0)
				return;
			const text = clipboardOutput.text;
			if (text.trim() === "")
				return;
			let lines = text.split("\n");
			lines = lines.slice(0, 50);
			for (const line of lines) {
				if (!line.trim())
					continue;
				const tab = line.indexOf("\t");
				if (tab < 0)
					continue;
				const itemId = line.slice(0, tab);
				const full = line.slice(tab + 1);
				const isImage = full.startsWith("[[ binary data") && full.includes("]]");
				clipboardModel.append({
					"itemId": itemId,
					"fullLine": line,
					"text": full.replace(/[\u001f\u001e]/g, " ").trim(),
					"preview": isImage ? "Imagem" : full.replace(/[\u001f\u001e]/g, " ").trim(),
					"isImage": isImage
				});
			}
			root.filterClipboard(searchField.text);
		}
	}

	Process {
		id: copyProcess

		stdout: StdioCollector {
			id: copyOutput
			waitForEnd: true
		}
	}

	// ---- UI ----

	Column {
		anchors.fill: parent
		anchors.leftMargin: Theme.roundScaled(12, root.sf)
		anchors.rightMargin: Theme.roundScaled(12, root.sf)
		anchors.topMargin: Theme.roundScaled(10, root.sf)
		anchors.bottomMargin: Theme.roundScaled(10, root.sf)
		spacing: Theme.roundScaled(8, root.sf)

		Row {
			width: parent.width
			spacing: Theme.roundScaled(8, root.sf)

			Rectangle {
				id: searchBoxBg
				width: parent.width - wipeButton.width - parent.spacing
				height: Theme.roundScaled(38, root.sf)
				radius: Theme.moduleRadius
				color: Theme.moduleFill
				border.width: 1
				border.color: Theme.popupBorder

				Text {
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					anchors.leftMargin: Theme.roundScaled(12, root.sf)
					text: "\uf002"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.fontSize
					color: Theme.fg
				}

				TextInput {
					id: searchField
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					anchors.leftMargin: Theme.roundScaled(34, root.sf)
					anchors.rightMargin: Theme.roundScaled(10, root.sf)
					color: Theme.fg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.fontSize
					selectByMouse: true
					clip: true

					Keys.onPressed: function(event) {
						if (event.key === Qt.Key_Up) {
							resultList.currentIndex = Math.max(resultList.currentIndex - 1, 0);
							event.accepted = true;
						} else if (event.key === Qt.Key_Down) {
							resultList.currentIndex = Math.min(resultList.currentIndex + 1, filteredModel.count - 1);
							event.accepted = true;
						} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
							let idx = resultList.currentIndex;
							if (idx >= 0 && idx < filteredModel.count) {
								root.copyItemDetached(filteredModel.get(idx).itemId);
								root.actionTriggered("copy");
							}
							event.accepted = true;
						} else if (event.key === Qt.Key_Delete) {
							let idx = resultList.currentIndex;
							if (idx >= 0 && idx < filteredModel.count) {
								root.deleteItem(idx, filteredModel.get(idx).fullLine);
								event.accepted = true;
							}
						}
						if (event.key === Qt.Key_Escape) {
							root.actionTriggered("close");
							event.accepted = true;
						}
					}

					onTextChanged: root.filterClipboard(searchField.text)
				}
			}

			ModuleButton {
				id: wipeButton
				width: Theme.roundScaled(38, root.sf)
				height: Theme.roundScaled(38, root.sf)
				visible: filteredModel.count > 0

				IconText {
					glyph: "\uf1f8"
					glyphColor: Theme.danger
				}

				onClicked: root.wipeClipboard()
			}
		}

		ListView {
			id: resultList
			width: parent.width
			height: parent.height - searchBoxBg.height - parent.spacing
			clip: true
			model: filteredModel
			currentIndex: -1
			spacing: Theme.roundScaled(2, root.sf)

			highlight: Rectangle {
				width: resultList.width
				color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
				radius: Theme.moduleRadius
			}
			highlightFollowsCurrentItem: true

			delegate: Item {
				id: entryRow
				required property string itemId
				required property var text
				required property string fullLine
				required property bool isImage

				width: resultList.width
				height: Theme.roundScaled(40, root.sf)

				Rectangle {
					id: rowHover
					anchors.fill: parent
					radius: Theme.moduleRadius
					color: hoverArea.containsMouse
						? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
						: "transparent"
				}

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: Theme.roundScaled(12, root.sf)
					anchors.rightMargin: Theme.roundScaled(8, root.sf)
					spacing: Theme.roundScaled(8, root.sf)

					IconText {
						glyph: entryRow.isImage ? "\uf1c5" : "\uf0ea"
						glyphColor: entryRow.isImage ? Theme.accent : Theme.fg
						Layout.preferredWidth: Theme.roundScaled(20, root.sf)
						Layout.fillHeight: true
					}

					Text {
						text: entryRow.isImage ? "Imagem (copiar)" : entryRow.text
						font.family: Theme.fontFamily
						font.pixelSize: Theme.fontSize
						color: Theme.fg
						elide: Text.ElideRight
						maximumLineCount: 1
						clip: true
						Layout.fillWidth: true
						Layout.fillHeight: true
						verticalAlignment: Text.AlignVCenter
					}

					IconText {
						glyph: "\uf1f8"
						glyphColor: Theme.danger
						visible: hoverArea.containsMouse
						Layout.preferredWidth: Theme.roundScaled(18, root.sf)
						Layout.fillHeight: true
					}
				}

				MouseArea {
					id: hoverArea
					anchors.fill: parent
					hoverEnabled: true

					onClicked: root.copyItemDetached(entryRow.itemId)
				}
			}
		}
	}

	Timer {
		id: deletingResetTimer
		interval: 500
		repeat: false
		onTriggered: root.isDeleting = false
	}

	Timer {
		id: wipeTimer
		interval: 500
		repeat: false
		onTriggered: root.isDeleting = false
	}

	Connections {
		target: root
		function onActionTriggered(action) {
			if (action === "copy" || action === "close")
				Quantified.actionClose();
		}
	}
}
