import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	active: popup ? popup.open : false

	readonly property string glyph: {
		if (NetworkService.state === 1)
			return "\uf1eb";
		if (NetworkService.state === 2)
			return "\uf6ff";
		return "\uf05aa";
	}

	IconText {
		glyph: root.glyph
		text: NetworkService.state === 1 ? NetworkService.ssid : NetworkService.state === 2 ? "eth" : ""
		glyphColor: root.active ? Theme.accent : NetworkService.state === 0 ? Theme.sage : Theme.fg
		textColor: Theme.fg
		maxTextWidth: 90
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}