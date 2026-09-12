import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	IconText {
		glyph: "\uf2db"
		text: SystemStats.cpu + "%"
		glyphColor: SystemStats.cpu >= 90 ? Theme.danger : Theme.fg
		textColor: SystemStats.cpu >= 90 ? Theme.danger : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}