import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	readonly property string volumeGlyph: {
		if (AudioService.muted || AudioService.volume === 0)
			return "\uf026";
		if (AudioService.volume < 50)
			return "\uf027";
		return "\uf028";
	}

	Column {
		anchors.fill: parent
		spacing: Theme.roundScaled(6, root.sf)
		topPadding: Theme.roundScaled(12, root.sf)
		bottomPadding: Theme.roundScaled(12, root.sf)
		leftPadding: Theme.roundScaled(16, root.sf)
		rightPadding: Theme.roundScaled(16, root.sf)

		Item {
			id: netRow
			width: parent.width
			height: Theme.roundScaled(28, root.sf)

			RowLayout {
				anchors.fill: parent
				spacing: Theme.roundScaled(10, root.sf)

				Text {
					text: NetworkService.state === 2 ? "\uf6ff"
						: NetworkService.state === 1 ? "\uf1eb" : "\uf05aa"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
					color: NetworkService.state === 0 ? Theme.sage : Theme.fg
					Layout.alignment: Qt.AlignVCenter
				}

				Text {
					text: "Rede"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}

				Text {
					text: NetworkService.state === 1
						? NetworkService.ssid + "  " + NetworkService.signal + "%"
						: NetworkService.state === 2 ? "eth" : "offline"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: Theme.stone
					Layout.alignment: Qt.AlignVCenter
					elide: Text.ElideRight
				}
			}
		}

		Item {
			id: volRow
			width: parent.width
			height: Theme.roundScaled(28, root.sf)

			RowLayout {
				anchors.fill: parent
				spacing: Theme.roundScaled(10, root.sf)

				Text {
					text: root.volumeGlyph
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
					color: AudioService.muted ? Theme.sage : Theme.fg
					Layout.alignment: Qt.AlignVCenter
				}

				Text {
					text: "Volume"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}

				Text {
					text: AudioService.muted ? "MUT " + AudioService.volume + "%" : AudioService.volume + "%"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: AudioService.muted ? Theme.sage : Theme.stone
					Layout.alignment: Qt.AlignVCenter
				}
			}
		}

		Item {
			id: briRow
			width: parent.width
			height: Theme.roundScaled(28, root.sf)
			visible: BacklightService.available

			RowLayout {
				anchors.fill: parent
				spacing: Theme.roundScaled(10, root.sf)

				Text {
					text: "\uf185"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
				}

				Text {
					text: "Brilho"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}

				Text {
					text: BacklightService.percent + "%"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: Theme.stone
					Layout.alignment: Qt.AlignVCenter
				}
			}
		}

		Item {
			id: memRow
			width: parent.width
			height: Theme.roundScaled(28, root.sf)

			RowLayout {
				anchors.fill: parent
				spacing: Theme.roundScaled(10, root.sf)

				Text {
					text: "\uf085"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
					color: SystemStats.memPct >= 90 ? Theme.danger : Theme.fg
					Layout.alignment: Qt.AlignVCenter
				}

				Text {
					text: "Memória"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}

				Text {
					text: SystemStats.memPct + "%"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: SystemStats.memPct >= 90 ? Theme.danger : Theme.stone
					Layout.alignment: Qt.AlignVCenter
				}
			}
		}

		Item {
			id: cpuRow
			width: parent.width
			height: Theme.roundScaled(28, root.sf)

			RowLayout {
				anchors.fill: parent
				spacing: Theme.roundScaled(10, root.sf)

				Text {
					text: "\uf2db"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
					color: SystemStats.cpu >= 90 ? Theme.danger : Theme.fg
					Layout.alignment: Qt.AlignVCenter
				}

				Text {
					text: "CPU"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					font.weight: Font.Bold
					color: Theme.fg
					Layout.alignment: Qt.AlignVCenter
					Layout.fillWidth: true
				}

				Text {
					text: SystemStats.cpu + "%"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: SystemStats.cpu >= 90 ? Theme.danger : Theme.stone
					Layout.alignment: Qt.AlignVCenter
				}
			}
		}
	}
}