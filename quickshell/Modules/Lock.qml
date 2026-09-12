import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	IconText {
		glyph: "\uf023"
		glyphColor: LockService.locked || LockService.fallbackActive ? Theme.accent : Theme.fg
	}

	onClicked: LockService.lock()
}