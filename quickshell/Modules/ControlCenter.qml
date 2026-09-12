import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	active: popup ? popup.open : false

	IconText {
		glyph: "\uf1de"
		glyphColor: root.active ? Theme.accent : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}