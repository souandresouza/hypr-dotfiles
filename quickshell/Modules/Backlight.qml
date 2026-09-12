import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	visible: BacklightService.available

	IconText {
		glyph: "\uf185"
		text: BacklightService.percent + "%"
		glyphColor: Theme.fg
		textColor: Theme.fg
	}

	onWheelUp: BacklightService.adjust(5)
	onWheelDown: BacklightService.adjust(-5)
}