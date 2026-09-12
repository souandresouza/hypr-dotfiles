import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	Column {
		anchors.fill: parent
		anchors.topMargin: Theme.roundScaled(8, sf)

		RowLayout {
			width: parent.width

			Text {
				text: "NOTIFICAÇÕES"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, sf)
				font.weight: Font.DemiBold
				color: Theme.sage
				Layout.leftMargin: Theme.roundScaled(14, sf)
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
			}

			ModuleButton {
				height: Theme.roundScaled(26, sf)
				active: NotificationsService.dndManual
				Layout.rightMargin: Theme.roundScaled(6, sf)

				IconText {
					glyph: "\uf186"
					fontSize: Theme.roundScaled(Theme.fontSize, sf)
					glyphColor: NotificationsService.dndManual ? Theme.accent : Theme.fg
					text: "N. Perturbe"
					textColor: Theme.fg
				}

				onClicked: NotificationsService.dndManual = !NotificationsService.dndManual
			}

			ModuleButton {
				visible: NotificationsService.count > 0
				height: Theme.roundScaled(26, sf)
				Layout.rightMargin: Theme.roundScaled(10, sf)

				IconText {
					text: "Limpar"
					fontSize: Theme.roundScaled(Theme.fontSizeSmall, sf)
					textColor: Theme.fg
				}

				onClicked: NotificationsService.clearAll()
			}
		}

		Item {
			width: parent.width
			height: parent.height - Theme.roundScaled(8, sf)

			ListView {
				id: list
				anchors.fill: parent
				clip: true
				model: NotificationsService.entries
				spacing: Theme.roundScaled(6, sf)
				boundsBehavior: Flickable.StopAtBounds

				delegate: NotificationCard {
					width: list.width - Theme.roundScaled(20, sf)
					x: Theme.roundScaled(10, sf)
					sf: root.sf
				}
			}

			Text {
				anchors.centerIn: parent
				text: "Nenhuma notificação"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, sf)
				color: Theme.stone
				visible: NotificationsService.count === 0
			}
		}
	}
}