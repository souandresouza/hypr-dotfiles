import QtQuick
import QtQuick.Layouts
import qs.Common

Item {
	id: root

	required property string glyph
	required property string label
	required property string value
	required property color glyphColor
	required property bool active
	signal toggled

	property real sf: 1

	height: Theme.roundScaled(40, root.sf)

	RowLayout {
		anchors.fill: parent
		spacing: Theme.roundScaled(10, root.sf)

		Text {
			text: root.glyph
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
			color: root.glyphColor
			Layout.alignment: Qt.AlignVCenter
		}

		Column {
			Layout.fillWidth: true
			spacing: Theme.roundScaled(2, root.sf)

			Text {
				text: root.label
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
				font.weight: Font.Bold
				color: Theme.fg
			}

			Text {
				text: root.value
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.stone
				elide: Text.ElideRight
				width: parent.width
			}
		}

		Rectangle {
			width: Theme.roundScaled(34, root.sf)
			height: Theme.roundScaled(16, root.sf)
			radius: height / 2
			color: root.active
				? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
				: Theme.moduleHover
			Layout.alignment: Qt.AlignVCenter

			Rectangle {
				width: Theme.roundScaled(12, root.sf)
				height: Theme.roundScaled(12, root.sf)
				radius: width / 2
				color: root.active ? Theme.accent : Theme.stone
				anchors.verticalCenter: parent.verticalCenter
				x: root.active ? parent.width - width - 2 : 2

				Behavior on x {
					NumberAnimation { duration: 120 }
				}
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled()
	}
}
