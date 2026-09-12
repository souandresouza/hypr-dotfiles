import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.Common
import qs.Widgets

Item {
	id: root

	property real sf: 1

	readonly property var items: SystemTray.items.values.filter(item => {
			const name = item && (item.title || item.id);
			return name && name.length > 0;
		})

	property Item menuRow: null

	function killTrayApp(item) {
		const tokens = [];
		[item.id, item.title].forEach(s => {
			if (!s)
				return;
			String(s).split(/[\s._()\-\/]+/).forEach(t => {
				t = t.toLowerCase().trim();
				if (t.length >= 4 && tokens.indexOf(t) === -1)
					tokens.push(t);
			});
		});
		if (tokens.length === 0)
			return;
		const list = tokens.map(t => "'" + t + "'").join(" ");
		killProc.exec(["sh", "-c",
			"for c in " + list + "; do " +
				"p=$(pgrep -f -i \"$c\" | head -8 | tr '\\n' ' '); " +
				"[ -n \"$p\" ] && { kill $p 2>/dev/null; break; }; " +
			"done"]);
	}

	Process {
		id: killProc
		stdout: StdioCollector {
			id: killColl
			waitForEnd: true
		}
	}

	component TrayRow: Item {
		id: row
		required property var item

		readonly property bool menuOpen: root.menuRow === row

		width: parent.width
		height: Theme.roundScaled(44, root.sf)
			+ (menuOpen ? Theme.roundScaled(112, root.sf) : 0)

		Behavior on height {
			NumberAnimation { duration: 140 }
		}

		Rectangle {
			anchors.fill: parent
			radius: Theme.roundScaled(6, root.sf)
			color: rowMouse.containsMouse || menuOpen
				? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
				: "transparent"
		}

		RowLayout {
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.roundScaled(44, root.sf)
			anchors.leftMargin: Theme.roundScaled(12, root.sf)
			anchors.rightMargin: Theme.roundScaled(12, root.sf)
			spacing: Theme.roundScaled(10, root.sf)

			Item {
				Layout.preferredWidth: Theme.roundScaled(20, root.sf)
				Layout.preferredHeight: Theme.roundScaled(20, root.sf)
				Layout.alignment: Qt.AlignVCenter

				Image {
					id: trayIcon
					anchors.fill: parent
					source: item.icon || ""
					asynchronous: true
					smooth: true
					fillMode: Image.PreserveAspectFit
					sourceSize {
						width: Theme.roundScaled(20, root.sf) * 2
						height: Theme.roundScaled(20, root.sf) * 2
					}
					visible: status === Image.Ready
				}

				Rectangle {
					anchors.fill: parent
					radius: width / 2
					color: Theme.moduleHover
					visible: trayIcon.status !== Image.Ready

					Text {
						anchors.centerIn: parent
						text: (item.title || item.id || "?").charAt(0).toUpperCase()
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(11, root.sf)
						color: Theme.stone
					}
				}
			}

			Text {
				text: item ? String(item.title || item.id || "") : ""
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
				color: Theme.fg
				elide: Text.ElideRight
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
			}

			Text {
				text: "\uf054"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: menuOpen ? Theme.accent : Theme.stone
				rotation: menuOpen ? 90 : 0
				Layout.alignment: Qt.AlignVCenter

				Behavior on rotation {
					NumberAnimation { duration: 120 }
				}
			}
		}

		Column {
			visible: menuOpen
			width: parent.width
			anchors.top: parent.top
			anchors.topMargin: Theme.roundScaled(48, root.sf)
			anchors.leftMargin: Theme.roundScaled(12, root.sf)
			anchors.rightMargin: Theme.roundScaled(12, root.sf)
			spacing: Theme.roundScaled(4, root.sf)

			ModuleButton {
				width: parent.width - Theme.roundScaled(24, root.sf)
				height: Theme.roundScaled(32, root.sf)
				accentColor: Theme.accent
				IconText {
					glyph: "\uf144"
					glyphSize: Theme.iconSize
					text: "Abrir"
					fontSize: Theme.fontSizeSmall
					textColor: Theme.fg
				}
				onClicked: {
					root.menuRow = null;
					item.activate();
				}
			}

			ModuleButton {
				width: parent.width - Theme.roundScaled(24, root.sf)
				height: Theme.roundScaled(32, root.sf)
				accentColor: Theme.accent
				visible: item ? item.hasMenu : false
				IconText {
					glyph: "\uf0c9"
					glyphSize: Theme.iconSize
					text: "Menu do aplicativo"
					fontSize: Theme.fontSizeSmall
					textColor: Theme.fg
				}
				onClicked: {
					root.menuRow = null;
					row.openNativeMenu();
				}
			}

			ModuleButton {
				width: parent.width - Theme.roundScaled(24, root.sf)
				height: Theme.roundScaled(32, root.sf)
				accentColor: Theme.danger
				IconText {
					glyph: "\uf05d"
					glyphSize: Theme.iconSize
					text: "Encerrar aplicativo"
					fontSize: Theme.fontSizeSmall
					textColor: Theme.fg
				}
				onClicked: {
					root.menuRow = null;
					root.killTrayApp(row.item);
				}
			}
		}

		QsMenuAnchor {
			id: menuAnchor
			menu: item ? item.menu : null
		}

		function openNativeMenu() {
			if (!item || !item.menu)
				return;
			const win = row.Window.window;
			if (!win || !win.contentItem)
				return;
			const p = row.mapToItem(win.contentItem, 0, 0);
			menuAnchor.anchor.window = win;
			menuAnchor.anchor.rect = Qt.rect(p.x, p.y, row.width, row.height);
			menuAnchor.open();
		}

		MouseArea {
			id: rowMouse
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.roundScaled(44, root.sf)
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			onClicked: (mouse) => {
				if (menuOpen) {
					root.menuRow = null;
					return;
				}
				if (mouse.button === Qt.RightButton)
					root.menuRow = row;
				else if (mouse.button === Qt.MiddleButton)
					item.secondaryActivate();
				else if (mouse.button === Qt.LeftButton)
					item.activate();
			}
			onWheel: (wheel) => item.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
		}
	}

	Column {
		anchors.fill: parent
		anchors.margins: Theme.roundScaled(6, root.sf)
		spacing: Theme.roundScaled(2, root.sf)

		Text {
			text: "Tray"
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			font.bold: true
			color: Theme.accent
			leftPadding: Theme.roundScaled(8, root.sf)
			topPadding: Theme.roundScaled(4, root.sf)
			bottomPadding: Theme.roundScaled(2, root.sf)
		}

		Text {
			text: "clique esquerdo: abrir   ·   clique direito: opções"
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			color: Theme.stone
			leftPadding: Theme.roundScaled(8, root.sf)
			bottomPadding: Theme.roundScaled(4, root.sf)
		}

		Repeater {
			model: root.items

			delegate: TrayRow {
				item: modelData
			}
		}

		Text {
			text: "Nenhum aplicativo no tray"
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			color: Theme.stone
			visible: root.items.length === 0
			leftPadding: Theme.roundScaled(8, root.sf)
			topPadding: Theme.roundScaled(12, root.sf)
		}
	}
}