import QtQuick
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	height: Theme.contentHeight

	IconText {
		text: "Tray"
		fontSize: Theme.fontSizeSmall
		textColor: parent.active ? Theme.accent : Theme.fg
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}