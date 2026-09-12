import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	readonly property string networkGlyph:
		NetworkService.state === 2 ? "\uf6ff" : NetworkService.state === 1 ? "\uf1eb" : "\uf05aa"
	readonly property string volumeGlyph: {
		if (AudioService.muted || AudioService.volume === 0)
			return "\uf026";
		if (AudioService.volume < 50)
			return "\uf027";
		return "\uf028";
	}

	Flickable {
		id: scroll
		anchors.fill: parent
		clip: true
		contentWidth: parent.width
		contentHeight: marginWrap.height
		boundsBehavior: Flickable.StopAtBounds

		Item {
			id: marginWrap
			x: Theme.roundScaled(20, root.sf)
			width: parent.width - Theme.roundScaled(40, root.sf)
			height: column.implicitHeight

			Column {
				id: column
				width: parent.width
				spacing: Theme.roundScaled(10, root.sf)
				topPadding: Theme.roundScaled(8, root.sf)
				bottomPadding: Theme.roundScaled(12, root.sf)

				Text {
					text: "CENTRAL"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: Theme.sage
					height: Theme.roundScaled(16, root.sf)
					verticalAlignment: Text.AlignVCenter
				}

				Item {
					id: netLink
					width: parent.width
					height: Theme.roundScaled(40, root.sf)

					RowLayout {
						anchors.fill: parent
						spacing: Theme.roundScaled(10, root.sf)

						Text {
							text: root.networkGlyph
							font.family: Theme.fontFamily
							font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
							color: NetworkService.state === 0 ? Theme.sage : Theme.fg
							Layout.alignment: Qt.AlignVCenter
						}

						Column {
							Layout.fillWidth: true
							spacing: Theme.roundScaled(2, root.sf)

							Text {
								text: "Rede"
								font.family: Theme.fontFamily
								font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
								font.weight: Font.Bold
								color: Theme.fg
							}

							Text {
								text: {
									if (NetworkService.state === 1) {
										if (NetworkService.ssid.length > 0)
											return NetworkService.ssid + "  " + NetworkService.signal + "%";
										return "Wi-Fi conectado";
									}
									if (NetworkService.state === 2)
										return "Ethernet";
									return "Sem conexão";
								}
								font.family: Theme.fontFamily
								font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
								color: Theme.stone
								elide: Text.ElideRight
								width: parent.width
							}
						}

						Text {
							text: "\uf054"
							font.family: Theme.fontFamily
							font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
							color: Theme.stone
							Layout.alignment: Qt.AlignVCenter
						}
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							const p = PopupService.network;
							if (p)
								p.toggleFrom(netLink);
						}
					}
				}

				ToggleRow {
					width: parent.width
					sf: root.sf
					glyph: "\uf294"
					label: "Bluetooth"
					value: BluetoothService.powered
						? (BluetoothService.connected > 0
							? BluetoothService.connected + " conectado(s)"
							: "Ligado")
						: "Desligado"
					glyphColor: BluetoothService.powered ? Theme.accent : Theme.sage
					active: BluetoothService.powered
					onToggled: BluetoothService.togglePower()
				}

				SliderRow {
					width: parent.width
					sf: root.sf
					glyph: root.volumeGlyph
					label: "Volume"
					glyphColor: AudioService.muted ? Theme.sage : Theme.fg
					value: AudioService.volume
					onChanged: (v) => {
						if (v === 0) {
							if (!AudioService.muted)
								AudioService.toggleMute();
						} else {
							AudioService.setVolume(v);
							if (AudioService.muted)
								AudioService.toggleMute();
						}
					}
				}

				SliderRow {
					width: parent.width
					sf: root.sf
					glyph: "\uf185"
					label: "Brilho"
					value: BacklightService.percent
					enabled: BacklightService.available
					visible: BacklightService.available
					onChanged: (v) => BacklightService.set(v)
				}

				StatRow {
					width: parent.width
					sf: root.sf
					label: "CPU"
					value: SystemStats.cpu + "%"
					percent: SystemStats.cpu / 100
					barColor: SystemStats.cpu >= 90 ? Theme.danger : Theme.accent
				}

				StatRow {
					width: parent.width
					sf: root.sf
					label: "GPU"
					value: SystemStats.gpu + "%"
					percent: SystemStats.gpu / 100
					barColor: SystemStats.gpu >= 90 ? Theme.danger : Theme.accentSoft
				}

				StatRow {
					width: parent.width
					sf: root.sf
					label: "MEM"
					value: SystemStats.memUsedMb + " / " + SystemStats.memTotalMb + " MiB"
					percent: SystemStats.memPct / 100
					barColor: SystemStats.memPct >= 90 ? Theme.danger : Theme.accentSoft
				}

				StatRow {
					width: parent.width
					sf: root.sf
					label: "TEMP"
					value: SystemStats.temp + "°C"
					percent: SystemStats.temp / 100
					barColor: SystemStats.temp >= 80 ? Theme.danger : Theme.olive
				}
			}
		}
	}
}