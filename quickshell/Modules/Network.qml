import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	active: popup ? popup.open : false

	contentCentered: true

	readonly property string glyph: ""

	IconText {
		glyph: root.glyph
		text: NetworkService.state === 1
			? NetworkService.ssid + "  " + NetworkService.signal + "%"
			: NetworkService.state === 2 ? "eth" : ""
		glyphColor: root.active ? Theme.accent : NetworkService.state === 0 ? Theme.sage : Theme.fg
		textColor: Theme.fg
		maxTextWidth: 220
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}