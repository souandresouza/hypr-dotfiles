import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	Item {
		width: 0
		height: 0
		visible: false
		SystemClock {
			id: clock
			precision: SystemClock.Seconds
			enabled: true
		}
	}

	IconText {
		glyph: "\uf017"
		text: Qt.formatTime(clock.date, "HH:mm:ss")
		glyphColor: Theme.fg
		textColor: Theme.fg
	}

onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}