import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: card

	required property var model
	property real sf: 1
	property bool toast: false

	readonly property var entry: card.model
		? NotificationsService.recordById(card.model.id)
		: undefined
	readonly property var e: card.entry
		? card.entry
		: ({ appName: "", image: "", time: 0, urgency: "normal", summary: "", body: "",
		     actions: [], hasInlineReply: false, placeholder: "", leaving: false })

	height: contentColumn.implicitHeight + Theme.roundScaled(16, sf) + Theme.roundScaled(12, sf)

	opacity: card.toast && card.e.leaving ? 0 : 1

	Behavior on opacity {
		NumberAnimation { duration: 180 }
	}

	function cardColor() {
		if (card.e.urgency === "critical")
			return Theme.danger;
		if (card.e.urgency === "low")
			return Theme.olive;
		return Theme.accent;
	}

	function sendReply() {
		if (!card.entry || !card.entry.notif || !card.entry.hasInlineReply)
			return;
		try {
			card.entry.notif.sendInlineReply(replyInput.text);
			replyInput.text = "";
		} catch (err) { console.warn("[cadrocbar] falha ao responder:", err.message); }
	}

	Rectangle {
		id: bg
		anchors.fill: parent
		radius: Theme.roundScaled(8, sf)
		color: hoverArea.containsMouse
			? Qt.rgba(Theme.popupBg.r, Theme.popupBg.g, Theme.popupBg.b, 1)
			: Theme.popupBg
		border.width: 1
		border.color: Qt.rgba(card.cardColor().r, card.cardColor().g, card.cardColor().b, 0.55)

		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			width: Theme.roundScaled(3, sf)
			radius: Theme.roundScaled(2, sf)
			color: card.cardColor()
		}
	}

	MouseArea {
		id: hoverArea
		anchors.fill: parent
		hoverEnabled: true
	}

	Column {
		id: contentColumn
		anchors.fill: parent
		anchors.leftMargin: Theme.roundScaled(12, sf)
		anchors.rightMargin: Theme.roundScaled(8, sf)
		anchors.topMargin: Theme.roundScaled(10, sf)
		anchors.bottomMargin: Theme.roundScaled(6, sf)
		spacing: Theme.roundScaled(4, sf)

		RowLayout {
			width: parent.width
			spacing: Theme.roundScaled(10, sf)

			Item {
				Layout.preferredWidth: Theme.roundScaled(30, sf)
				Layout.preferredHeight: Theme.roundScaled(30, sf)

				Image {
					id: notifImage
					anchors.fill: parent
					source: card.e.image
					fillMode: Image.PreserveAspectCrop
					clip: true
					sourceSize.width: 64
					sourceSize.height: 64
					visible: card.e.image && card.e.image.length > 0
				}

				Rectangle {
					anchors.fill: parent
					visible: !card.e.image || card.e.image.length === 0
					radius: Theme.roundScaled(6, sf)
					color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

					Text {
						anchors.centerIn: parent
						text: NotificationsService.appGlyph(card.e.appName)
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.iconSize, sf)
						color: card.cardColor()
					}
				}
			}

			Column {
				Layout.fillWidth: true
				spacing: 0

				Text {
					width: parent.width
					text: card.e.appName.length > 0 ? card.e.appName : "Notificação"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, sf)
					font.weight: Font.DemiBold
					color: Theme.stone
					elide: Text.ElideRight
				}

				Text {
					width: parent.width
					text: NotificationsService.fmtTime(card.e.time)
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(9, sf)
					color: Theme.stone
				}
			}

			ModuleButton {
				dim: true
				framed: false
				width: Theme.roundScaled(24, sf)
				height: Theme.roundScaled(24, sf)
				Layout.preferredWidth: Theme.roundScaled(24, sf)
				Layout.preferredHeight: Theme.roundScaled(24, sf)
				padding: 0
				contentCentered: true

				IconText {
					glyph: "\uf00d"
					glyphSize: Theme.roundScaled(11, sf)
					glyphColor: Theme.stone
				}

				onClicked: NotificationsService.closeEntry(card.entry)
			}
		}

		Text {
			width: parent.width
			text: card.e.summary
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSize, sf)
			font.weight: Font.Bold
			color: Theme.fg
			wrapMode: Text.Wrap
			visible: card.e.summary.length > 0
		}

		Text {
			width: parent.width
			text: card.e.body
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSize, sf)
			color: Theme.fg
			wrapMode: Text.Wrap
			visible: card.e.body.length > 0
		}

		Row {
			width: parent.width
			spacing: Theme.roundScaled(6, sf)
			visible: card.e.actions.length > 0

			Repeater {
				model: card.e.actions

				delegate: ModuleButton {
					accentColor: card.cardColor()
					height: Theme.roundScaled(26, sf)

					IconText {
						text: modelData.text
						fontSize: Theme.roundScaled(Theme.fontSizeSmall, sf)
						textColor: Theme.fg
					}

					onClicked: {
						if (!card.entry || !card.entry.notif)
							return;
						const acts = card.entry.notif.actions;
						for (let i = 0; i < acts.length; i++) {
							if (String(acts[i].identifier) === String(modelData.identifier)) {
								acts[i].invoke();
								break;
							}
						}
					}
				}
			}
		}

		RowLayout {
			width: parent.width
			spacing: Theme.roundScaled(6, sf)
			visible: card.e.hasInlineReply

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: Theme.roundScaled(28, sf)
				radius: Theme.roundScaled(4, sf)
				color: Theme.moduleHover
				border.width: 1
				border.color: replyInput.activeFocus
					? Qt.rgba(card.cardColor().r, card.cardColor().g, card.cardColor().b, 0.7)
					: "transparent"

				TextInput {
					id: replyInput
					anchors.fill: parent
					anchors.leftMargin: Theme.roundScaled(8, sf)
					anchors.rightMargin: Theme.roundScaled(8, sf)
					verticalAlignment: TextInput.AlignVCenter
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, sf)
					color: Theme.fg
					selectionColor: card.cardColor()
					selectedTextColor: Theme.bg
					clip: true
					onAccepted: card.sendReply()
				}
			}

			ModuleButton {
				accentColor: card.cardColor()
				height: Theme.roundScaled(28, sf)
				Layout.preferredHeight: Theme.roundScaled(28, sf)

				IconText {
					glyph: "\uf1d8"
					glyphColor: Theme.accent
				}

				onClicked: card.sendReply()
			}
		}
	}
}