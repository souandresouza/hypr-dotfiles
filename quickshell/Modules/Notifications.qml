import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	active: popup ? popup.open : false
	urgent: NotificationsService.hasUrgent

	IconText {
		glyph: NotificationsService.dnd ? "\uf1f6" : "\uf0f3"
		glyphColor: root.active
			? Theme.accent
			: root.urgent ? Theme.danger : NotificationsService.dnd ? Theme.stone : Theme.fg
	}

	Text {
		text: NotificationsService.count > 9 ? "9+" : NotificationsService.count
		visible: NotificationsService.count > 0
		font.family: Theme.fontFamily
		font.pixelSize: Theme.fontSizeSmall
		font.weight: Font.DemiBold
		color: root.urgent ? Theme.danger : Theme.accent
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}