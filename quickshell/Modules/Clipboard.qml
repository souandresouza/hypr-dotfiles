import QtQuick
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	IconText {
		glyph: "\uf0ea"
		glyphColor: Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}
