import QtQuick
import qs.Services
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	property var screen: null
	property var _ref: LauncherService

	height: Theme.contentHeight
	IconText {
		glyph: "\uf009"
		glyphColor: Theme.fg
	}

	onClicked: LauncherService.toggle(root.screen)
}