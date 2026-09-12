import QtQuick
import QtQuick.Layouts
import qs.Common

Item {
	id: root

	required property string glyph
	required property string label
	property color glyphColor: Theme.fg
	property real value: 0
	property bool enabled: true
	property real sf: 1
	signal changed(real v)

	height: Theme.roundScaled(44, root.sf)

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
			spacing: Theme.roundScaled(3, root.sf)

			RowLayout {
				width: parent.width

				Text {
					text: root.label
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.fillWidth: true
				}

				Text {
					text: Math.round(root.value) + "%"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: root.enabled ? Theme.stone : Theme.sage
				}
			}

			HSlider {
				width: parent.width
				sf: root.sf
				value: root.value
				enabled: root.enabled
				onValuePushed: (v) => root.changed(v)
			}
		}
	}
}
