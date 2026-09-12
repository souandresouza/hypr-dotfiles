import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	required property var screen

	readonly property var toplevel: Hyprland.activeToplevel
	readonly property string title: toplevel && toplevel.title ? toplevel.title : ""

	height: Theme.contentHeight
	visible: title.length > 0

	IconText {
		glyph: "\uf2d2"
		glyphColor: Theme.accent
		text: root.title
		textColor: Theme.fg
		maxTextWidth: 220
	}
}