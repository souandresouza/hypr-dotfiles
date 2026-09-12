import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	IconText {
		glyph: IdleInhibitorService.active ? "\uf06e" : "\uf070"
		glyphColor: IdleInhibitorService.active ? Theme.accent : Theme.fg
	}

	onClicked: IdleInhibitorService.toggle()
}