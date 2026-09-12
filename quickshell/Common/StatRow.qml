import QtQuick
import qs.Common

Column {
	id: root

	required property string label
	required property string value
	required property real percent
	required property color barColor
	property real sf: 1

	spacing: Theme.roundScaled(4, root.sf)

	Row {
		width: parent.width
		spacing: Theme.roundScaled(8, root.sf)

		Text {
			text: root.label
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			font.weight: Font.Bold
			color: Theme.fg
			width: Theme.roundScaled(36, root.sf)
		}

		Text {
			text: root.value
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			color: Theme.stone
			width: parent.width - Theme.roundScaled(44, root.sf)
			elide: Text.ElideRight
			horizontalAlignment: Text.AlignRight
		}
	}

	Rectangle {
		width: parent.width
		height: Theme.roundScaled(6, root.sf)
		radius: Theme.roundScaled(3, root.sf)
		color: Theme.moduleHover

		Rectangle {
			width: parent.width * Theme.clamp(root.percent, 0, 1)
			height: parent.height
			radius: Theme.roundScaled(3, root.sf)
			color: root.barColor
		}
	}
}
