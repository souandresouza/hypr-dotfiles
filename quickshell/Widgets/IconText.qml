import QtQuick
import qs.Common

Item {
	id: root

	property string glyph: ""
	property string text: ""
	property color glyphColor: Theme.fg
	property color textColor: Theme.fg
	property int fontSize: Theme.fontSize
	property int glyphSize: Theme.iconSize
	property int maxTextWidth: 0
	property int fontWeight: Font.Normal

	implicitWidth: (glyphText.visible ? glyphText.width : 0) + (label.visible && glyphText.visible ? spacing : 0) + (label.visible ? label.width : 0)
	implicitHeight: Math.max(glyphText.visible ? glyphText.height : 0, label.visible ? label.height : 0)

	property int spacing: 6

	Text {
		id: glyphText
		text: root.glyph
		font.family: Theme.fontFamily
		font.pixelSize: root.glyphSize
		color: root.glyphColor
		visible: root.glyph.length > 0
		verticalAlignment: Text.AlignVCenter
		y: (parent.height - height) / 2
	}

	Text {
		id: label
		text: root.text
		font.family: Theme.fontFamily
		font.pixelSize: root.fontSize
		font.weight: root.fontWeight
		color: root.textColor
		visible: root.text.length > 0
		verticalAlignment: Text.AlignVCenter
		x: glyphText.visible ? glyphText.width + root.spacing : 0
		y: (parent.height - height) / 2
		width: root.maxTextWidth > 0 ? root.maxTextWidth : implicitWidth
		elide: root.maxTextWidth > 0 ? Text.ElideRight : Text.ElideNone
		maximumLineCount: 1
	}
}