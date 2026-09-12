import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	readonly property string glyph: {
		if (AudioService.muted || AudioService.volume === 0)
			return "\uf026";
		if (AudioService.volume < 50)
			return "\uf027";
		return "\uf028";
	}

	IconText {
		glyph: root.glyph
		text: AudioService.muted ? "MUT" : AudioService.volume + "%"
		glyphColor: AudioService.muted ? Theme.sage : Theme.fg
		textColor: AudioService.muted ? Theme.sage : Theme.fg
	}

	onClicked: AudioService.toggleMute()
	onWheelUp: AudioService.adjust(5)
	onWheelDown: AudioService.adjust(-5)
}