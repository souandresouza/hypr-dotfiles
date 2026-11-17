import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	visible: WeatherService.available

	IconText {
		glyph: WeatherService.glyph
		text: WeatherService.temp
		glyphColor: Theme.accent
		textColor: Theme.fg
	}
}