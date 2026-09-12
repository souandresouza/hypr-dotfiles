import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	readonly property bool hot: SystemStats.temp >= 80

	IconText {
		glyph: "\uf2c9"
		text: SystemStats.temp + "°C"
		glyphColor: root.hot ? Theme.danger : Theme.fg
		textColor: root.hot ? Theme.danger : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}