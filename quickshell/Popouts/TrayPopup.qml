import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Common

Item {
	id: root

	property real sf: 1

	readonly property var items: SystemTray.items.values.filter(item => {
			const name = item && (item.title || item.id);
			return name && name.length > 0;
		})

	component TrayRow: Item {
		id: row
		required property var item

		height: Theme.roundScaled(40, root.sf)

		Rectangle {
			anchors.fill: parent
			radius: Theme.roundScaled(6, root.sf)
			color: rowMouse.containsMouse
				? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
				: "transparent"
		}

		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: Theme.roundScaled(14, root.sf)
			anchors.rightMargin: Theme.roundScaled(14, root.sf)
			spacing: Theme.roundScaled(10, root.sf)

			Text {
				text: "\u25CF"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(8, root.sf)
				color: Theme.sage
				Layout.alignment: Qt.AlignVCenter
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
		}

		MouseArea {
			id: rowMouse
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			onClicked: (mouse) => {
				if (mouse.button === Qt.RightButton)
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