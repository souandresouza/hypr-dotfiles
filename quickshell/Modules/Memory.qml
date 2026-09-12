import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	IconText {
		glyph: "\uf085"
		text: SystemStats.memPct + "%"
		glyphColor: SystemStats.memPct >= 90 ? Theme.danger : Theme.fg
		textColor: SystemStats.memPct >= 90 ? Theme.danger : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}