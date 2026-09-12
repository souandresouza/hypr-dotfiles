import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import Quickshell.Services.SystemTray

ModuleButton {
	id: root

	property var popup: null

	readonly property int liveCount: SystemTray.items.values.length

	IconText {
		text: "Tray" + (root.liveCount > 0 ? " " + root.liveCount : "")
		fontSize: Theme.fontSizeSmall
		textColor: parent.active ? Theme.accent : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}