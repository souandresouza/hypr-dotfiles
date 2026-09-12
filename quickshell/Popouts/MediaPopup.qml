import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	readonly property var player: MprisService.player

	function send(id, cmd, value) {
		MprisService.send(id, cmd, value);
	}

	function fmtTime(us) {
		const totalSec = Math.max(0, Math.floor((us || 0) / 1000000));
		const h = Math.floor(totalSec / 3600);
		const m = Math.floor((totalSec % 3600) / 60);
		const s = totalSec % 60;
		const mm = String(m).padStart(2, "0");
		const ss = String(s).padStart(2, "0");
		return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss;
	}

	Column {
		anchors.fill: parent
		anchors.margins: Theme.roundScaled(16, root.sf)
		spacing: Theme.roundScaled(12, root.sf)

		Text {
			text: "MÍDIA"
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			color: Theme.sage
			verticalAlignment: Text.AlignVCenter
			height: Theme.roundScaled(16, root.sf)
		}

		Rectangle {
			width: parent.width
			height: Theme.roundScaled(130, root.sf)
			radius: Theme.moduleRadius
			color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.6)
			border.color: Theme.moduleHover
			border.width: 1
			visible: MprisService.player !== null

			Row {
				anchors.fill: parent
				anchors.margins: Theme.roundScaled(12, root.sf)
				spacing: Theme.roundScaled(12, root.sf)

				Column {
					width: art.width
					height: parent.height
					spacing: Theme.roundScaled(8, root.sf)

					Rectangle {
						id: art
						width: Theme.roundScaled(86, root.sf)
						height: Theme.roundScaled(86, root.sf)
						radius: Theme.moduleRadius
						color: Theme.moduleHover
						clip: true

						Image {
							id: artIcon
							anchors.fill: parent
							source: MprisService.player ? MprisService.player.artUrl : ""
							asynchronous: true
							smooth: true
							fillMode: Image.PreserveAspectCrop
							visible: source.toString().length > 0 && status === Image.Ready
						}

						Text {
							anchors.centerIn: parent
							text: "\uf001"
							font.family: Theme.fontFamily
							font.pixelSize: Theme.roundScaled(30, root.sf)
							color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.4)
							visible: !artIcon.visible
						}
					}

					Row {
						id: controlsRow
						spacing: Theme.roundScaled(4, root.sf)

						ModuleButton {
							width: Theme.roundScaled(22, root.sf)
							height: Theme.roundScaled(22, root.sf)
							padding: Theme.roundScaled(4, root.sf)
							visible: MprisService.player ? MprisService.player.canGoPrevious : false
							IconText { glyph: "\uf048" }
							onClicked: root.send(MprisService.player.id, "previous")
						}

						ModuleButton {
							id: playBtn
							width: Theme.roundScaled(28, root.sf)
							height: Theme.roundScaled(22, root.sf)
							padding: Theme.roundScaled(4, root.sf)
							contentCentered: true
							accentColor: Theme.accent
							active: MprisService.playing
							IconText {
								glyph: MprisService.playing ? "\uf04c" : "\uf04b"
								glyphColor: MprisService.playing ? Theme.accent : Theme.fg
							}
							onClicked: MprisService.togglePlayback(MprisService.player)
						}

						ModuleButton {
							width: Theme.roundScaled(22, root.sf)
							height: Theme.roundScaled(22, root.sf)
							padding: Theme.roundScaled(4, root.sf)
							visible: MprisService.player ? MprisService.player.canGoNext : false
							IconText { glyph: "\uf051" }
							onClicked: root.send(MprisService.player.id, "next")
						}
					}
				}

				Column {
					width: parent.width - art.width - parent.spacing
					height: parent.height
					spacing: Theme.roundScaled(6, root.sf)

					Text {
						width: parent.width
						text: MprisService.player ? MprisService.player.title || "" : ""
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeLarge, root.sf)
						font.weight: Font.Bold
						color: Theme.fg
						elide: Text.ElideRight
						wrapMode: Text.NoWrap
					}

					Text {
						width: parent.width
						text: MprisService.player ? [
							MprisService.player.artist,
							MprisService.player.album
						].filter(x => x && x.length > 0).join("   ") : ""
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
						color: Theme.stone
						elide: Text.ElideRight
					}
				}
			}
		}

		Text {
			width: parent.width
			text: MprisService.player === null ? "Nenhuma mídia em reprodução" : ""
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
			color: Theme.stone
			horizontalAlignment: Text.AlignHCenter
		}

		Row {
			width: parent.width
			spacing: Theme.roundScaled(8, root.sf)
			visible: MprisService.player !== null && MprisService.player.length > 0

			Text {
				id: elapsedLabel
				text: MprisService.player ? root.fmtTime(MprisService.player.position) : "0:00"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.stone
				verticalAlignment: Text.AlignVCenter
			}

			Rectangle {
				width: parent.width - elapsedLabel.implicitWidth - totalLabel.implicitWidth - parent.spacing * 2
				height: Theme.roundScaled(6, root.sf)
				radius: Theme.roundScaled(3, root.sf)
				color: Theme.moduleHover
				anchors.verticalCenter: parent.verticalCenter

				Rectangle {
					readonly property real fraction: MprisService.player && MprisService.player.length > 0
						? Math.max(0, Math.min(1, MprisService.player.position / MprisService.player.length))
						: 0
					width: parent.width * fraction
					anchors.verticalCenter: parent.verticalCenter
					height: parent.height
					radius: parent.radius
					color: Theme.accent
				}
			}

			Text {
				id: totalLabel
				text: MprisService.player ? root.fmtTime(MprisService.player.length) : "0:00"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.stone
				verticalAlignment: Text.AlignVCenter
			}
		}

		Row {
			width: parent.width
			spacing: Theme.roundScaled(8, root.sf)
			visible: MprisService.player !== null

			Text {
				id: volGlyph
				text: MprisService.player && (MprisService.player.volume || 0) > 0.5 ? "\uf028" : MprisService.player && (MprisService.player.volume || 0) > 0 ? "\uf027" : "\uf026"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
				color: Theme.accent
				verticalAlignment: Text.AlignVCenter
			}

			Text {
				id: volLabel
				text: {
					const v = MprisService.player ? MprisService.player.volume : 0;
					if (typeof v !== "number" || v < 0)
						return "—";
					return Math.round(v * 100) + "%";
				}
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.fg
				verticalAlignment: Text.AlignVCenter
			}

			Rectangle {
				id: volTrack
				width: parent.width - volLabel.implicitWidth - volGlyph.implicitWidth - parent.spacing * 2
				height: Theme.roundScaled(6, root.sf)
				radius: Theme.roundScaled(3, root.sf)
				color: Theme.moduleHover
				anchors.verticalCenter: parent.verticalCenter

				Rectangle {
					readonly property real vfrac: MprisService.player && typeof MprisService.player.volume === "number" && MprisService.player.volume >= 0
						? Math.max(0, Math.min(1, MprisService.player.volume))
						: 0
					width: parent.width * vfrac
					height: parent.height
					radius: parent.radius
					color: Theme.accent
				}

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton
					onClicked: (mouse) => {
						const frac = Math.max(0, Math.min(1, mouse.x / volTrack.width));
						MprisService.volumeSet(MprisService.player, frac);
					}
					onWheel: (wheel) => {
						const v = MprisService.player ? MprisService.player.volume : 0;
						const base = typeof v === "number" && v >= 0 ? v : 0;
						const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
						MprisService.volumeSet(MprisService.player, base + step);
					}
				}
			}
		}

		Row {
			width: parent.width
			spacing: Theme.roundScaled(6, root.sf)
			visible: MprisService.players.length > 0

			Repeater {
				model: MprisService.players

				delegate: ModuleButton {
					required property var modelData

					readonly property bool isCurrent: MprisService.player === modelData

					width: (parent.width - Theme.roundScaled(12, root.sf)) / Math.max(1, MprisService.players.length)
					height: Theme.roundScaled(30, root.sf)
					active: modelData.status === "Playing"
					padding: Theme.roundScaled(8, root.sf)

					Text {
						text: {
							const id = modelData.identity || "player";
							return id.length > 12 ? id.substring(0, 11) + "…" : id;
						}
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
						color: modelData.status === "Playing" ? Theme.accent : Theme.fg
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						width: parent.width
					}

					onClicked: root.send(modelData.id, "raise")
				}
			}
		}
	}
}