import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services

Item {
	id: root

	property real sf: 1

	signal actionTriggered(string action)

	function run(action) {
		if (action === "lock")
			LockService.lock();
		else if (action === "suspend")
			Quickshell.execDetached(["systemctl", "suspend"]);
		else if (action === "logout")
			Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
		else if (action === "reboot")
			Quickshell.execDetached(["systemctl", "reboot"]);
		else if (action === "poweroff")
			Quickshell.execDetached(["systemctl", "poweroff"]);
		root.actionTriggered(action);
	}

	component PowerRow: Item {
		id: row
		required property string glyph
		required property string label
		required property string action
		required property color rowColor

		width: rowParent.width
		height: Theme.roundScaled(42, root.sf)

		Rectangle {
			anchors.fill: parent
			radius: Theme.roundScaled(6, root.sf)
			color: rowMouse.containsMouse
				? Qt.rgba(row.rowColor.r, row.rowColor.g, row.rowColor.b, 0.12)
				: "transparent"
		}

		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: Theme.roundScaled(14, root.sf)
			anchors.rightMargin: Theme.roundScaled(14, root.sf)
			spacing: Theme.roundScaled(10, root.sf)

			Text {
				text: row.glyph
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
				color: row.rowColor
				Layout.alignment: Qt.AlignVCenter
			}

			Text {
				text: row.label
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
				color: Theme.fg
				Layout.alignment: Qt.AlignVCenter
			}
		}

		MouseArea {
			id: rowMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: root.run(row.action)
		}
	}

	Item {
		id: rowParent
		anchors.fill: parent
	}

	Column {
		anchors.fill: parent
		anchors.margins: Theme.roundScaled(6, root.sf)
		spacing: Theme.roundScaled(4, root.sf)

		PowerRow {
			glyph: "\uf023"
			label: "Bloquear"
			action: "lock"
			rowColor: Theme.fg
		}

		PowerRow {
			glyph: "\uf186"
			label: "Suspender"
			action: "suspend"
			rowColor: Theme.fg
		}

		PowerRow {
			glyph: "\uf2f5"
			label: "Sair"
			action: "logout"
			rowColor: Theme.fg
		}

		PowerRow {
			glyph: "\uf2f1"
			label: "Reiniciar"
			action: "reboot"
			rowColor: Theme.danger
		}

		PowerRow {
			glyph: "\uf011"
			label: "Desligar"
			action: "poweroff"
			rowColor: Theme.danger
		}
	}
}