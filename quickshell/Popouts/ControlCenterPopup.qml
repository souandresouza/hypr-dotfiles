import QtQuick
import QtQuick.Layouts
import Quickshell
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

	component WifiRow: Item {
		id: wifiRow
		required property var network
		property bool expanded: false

		width: parent.width
		height: expanded
			? Theme.roundScaled(88, root.sf)
			: Theme.roundScaled(34, root.sf)

		readonly property bool connected: network.ssid != null && network.ssid.length > 0 && network.ssid === NetworkService.ssid

		Rectangle {
			anchors.fill: parent
			radius: Theme.roundScaled(6, root.sf)
			color: wifiMouse.containsMouse
				? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
				: "transparent"
		}

		RowLayout {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.leftMargin: Theme.roundScaled(10, root.sf)
			anchors.rightMargin: Theme.roundScaled(10, root.sf)
			height: Theme.roundScaled(34, root.sf)
			spacing: Theme.roundScaled(8, root.sf)

			Text {
				text: wifiRow.connected ? "\uf0e8" : network.secured ? "\uf023" : "\uf1eb"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.iconSize, root.sf)
				color: wifiRow.connected
					? Theme.accent
					: network.secured ? Theme.sage : Theme.fg
				Layout.alignment: Qt.AlignVCenter
			}

			Text {
				text: network.ssid || ""
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
				font.weight: wifiRow.connected ? Font.Bold : Font.Normal
				color: wifiRow.connected ? Theme.accent : Theme.fg
				elide: Text.ElideRight
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
			}

			Text {
				text: (network.signal != null ? network.signal : 0) + "%"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.stone
				Layout.alignment: Qt.AlignVCenter
			}
		}

		MouseArea {
			id: wifiMouse
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.roundScaled(34, root.sf)
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				if (wifiRow.connected)
					return;
				if (network.secured) {
					if (!wifiRow.expanded) {
						wifiRow.expanded = true;
						passField.forceActiveFocus();
					}
				} else {
					NetworkService.connectTo(network.ssid, "");
				}
			}
		}

		RowLayout {
			visible: wifiRow.expanded
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.topMargin: Theme.roundScaled(38, root.sf)
			anchors.leftMargin: Theme.roundScaled(10, root.sf)
			anchors.rightMargin: Theme.roundScaled(10, root.sf)
			height: Theme.roundScaled(34, root.sf)
			spacing: Theme.roundScaled(8, root.sf)

			Rectangle {
				Layout.fillWidth: true
				Layout.fillHeight: true
				color: Theme.moduleHover
				radius: Theme.roundScaled(4, root.sf)
				border.color: passField.activeFocus ? Theme.accent : "transparent"
				border.width: 1

				TextInput {
					id: passField
					anchors.fill: parent
					anchors.leftMargin: Theme.roundScaled(10, root.sf)
					anchors.rightMargin: Theme.roundScaled(10, root.sf)
					verticalAlignment: TextInput.AlignVCenter
					echoMode: TextInput.Password
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSize, root.sf)
					color: Theme.fg
					selectionColor: Theme.accent
					selectedTextColor: Theme.bg
					inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
					onAccepted: {
						wifiRow.expanded = false;
						NetworkService.connectTo(wifiRow.network.ssid, text);
					}
					Keys.onPressed: (event) => {
						if (event.key === Qt.Key_Escape) {
							wifiRow.expanded = false;
							event.accepted = true;
						}
					}
				}
			}

			ModuleButton {
				property color btnColor: Theme.accent
				accentColor: Theme.accent
				height: Theme.roundScaled(30, root.sf)
				IconText {
					text: "Conectar"
					fontSize: Theme.fontSizeSmall
					textColor: Theme.fg
				}
				onClicked: {
					wifiRow.expanded = false;
					NetworkService.connectTo(wifiRow.network.ssid, passField.text);
				}
			}
		}
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

			ToggleRow {
				width: parent.width
				sf: root.sf
				glyph: root.networkGlyph
				label: "Rede"
				value: {
					if (NetworkService.state === 1) {
						if (NetworkService.ssid.length > 0)
							return NetworkService.ssid + "  " + NetworkService.signal + "%";
						return "Wi-Fi conectado";
					}
					if (NetworkService.state === 2)
						return "Ethernet";
					return "Sem conexão";
				}
				glyphColor: NetworkService.state === 0 ? Theme.sage : Theme.fg
				active: NetworkService.wifiEnabled
				onToggled: NetworkService.toggleWifi()
			}

			Column {
				width: parent.width
				spacing: Theme.roundScaled(2, root.sf)
				visible: NetworkService.wifiEnabled && NetworkService.networks.length > 0

				Text {
					text: "REDES WI-FI"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: Theme.sage
					height: Theme.roundScaled(18, root.sf)
					topPadding: Theme.roundScaled(4, root.sf)
					verticalAlignment: Text.AlignVCenter
				}

				Repeater {
					model: NetworkService.networks

					delegate: WifiRow {
						network: modelData
					}
				}

				Text {
					visible: NetworkService.connectFeedback.length > 0
					text: NetworkService.connectFeedback
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: Theme.stone
					wrapMode: Text.Wrap
					width: parent.width
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