import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

Item {
	id: root

	property real sf: 1

	property var netInfo: ({ ssid: "", conn: "", device: "", ip: "", gateway: "", band: "", psk: "" })
	property string qrSource: ""
	property bool qrShow: false

	readonly property bool netConnected: root.netInfo.ssid
		? root.netInfo.ssid.length > 0
		: false

	function refreshNetInfo() {
		netInfoProc.exec(["sh", "-c", Theme.binDir + "/wifi.sh info"]);
	}

	function pinWifiBand(value) {
		bandPinProc.exec(["sh", "-c", Theme.binDir + "/wifi.sh band " + value]);
	}

	function showQr() {
		qrProc.exec(["sh", "-c", Theme.binDir + "/wifi.sh qr"]);
	}

	Process {
		id: netInfoProc
		stdout: StdioCollector {
			id: netInfoColl
			waitForEnd: true
		}
		onExited: () => {
			const raw = netInfoColl.text.toString().trim();
			if (raw.length > 0 && raw.startsWith("{")) {
				try {
					root.netInfo = JSON.parse(raw);
				} catch (e) { /* ignore */ }
			}
		}
	}

	Process {
		id: bandPinProc
		stdout: StdioCollector {
			id: bandPinColl
			waitForEnd: true
		}
		onExited: () => {
			Qt.callLater(() => root.refreshNetInfo());
		}
	}

	Process {
		id: qrProc
		stdout: StdioCollector {
			id: qrColl
			waitForEnd: true
		}
		onExited: () => {
			const out = qrColl.text.toString().trim();
			if (out.length > 0 && out.startsWith("/")) {
				root.qrSource = "file://" + out;
				root.qrShow = true;
			}
		}
	}

	Timer {
		interval: 8000
		running: true
		repeat: true
		onTriggered: root.refreshNetInfo()
	}

	Component.onCompleted: root.refreshNetInfo()

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
				spacing: Theme.roundScaled(6, root.sf)
				visible: root.netConnected

				Text {
					width: parent.width
					text: root.netInfo.ip
						+ (root.netInfo.gateway ? "   GW " + root.netInfo.gateway : "")
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: Theme.stone
					elide: Text.ElideRight
				}

				RowLayout {
					width: parent.width
					spacing: Theme.roundScaled(4, root.sf)

					Text {
						text: "BANDA"
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
						font.weight: Font.DemiBold
						color: Theme.sage
						Layout.alignment: Qt.AlignVCenter
						Layout.rightMargin: Theme.roundScaled(6, root.sf)
					}

					ModuleButton {
						readonly property bool chipActive: root.netInfo.band === "2.4GHz"
						accentColor: chipActive
							? Theme.accent
							: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
						height: Theme.roundScaled(24, root.sf)
						Layout.preferredWidth: Theme.roundScaled(40, root.sf)
						contentCentered: true
						IconText {
							text: "2.4"
							fontSize: Theme.fontSizeSmall
							textColor: Theme.fg
						}
						onClicked: root.pinWifiBand("bg")
					}

					ModuleButton {
						readonly property bool chipActive: root.netInfo.band === "5GHz"
						accentColor: chipActive
							? Theme.accent
							: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
						height: Theme.roundScaled(24, root.sf)
						Layout.preferredWidth: Theme.roundScaled(40, root.sf)
						contentCentered: true
						IconText {
							text: "5"
							fontSize: Theme.fontSizeSmall
							textColor: Theme.fg
						}
						onClicked: root.pinWifiBand("a")
					}

					ModuleButton {
						readonly property bool chipActive: root.netInfo.band === "6GHz"
						accentColor: chipActive
							? Theme.accent
							: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
						height: Theme.roundScaled(24, root.sf)
						Layout.preferredWidth: Theme.roundScaled(40, root.sf)
						contentCentered: true
						IconText {
							text: "6"
							fontSize: Theme.fontSizeSmall
							textColor: Theme.fg
						}
						onClicked: root.pinWifiBand("ax")
					}

					ModuleButton {
						readonly property bool chipActive:
							root.netInfo.band !== "2.4GHz"
							&& root.netInfo.band !== "5GHz"
							&& root.netInfo.band !== "6GHz"
						accentColor: chipActive
							? Theme.accent
							: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
						height: Theme.roundScaled(24, root.sf)
						Layout.preferredWidth: Theme.roundScaled(44, root.sf)
						contentCentered: true
						IconText {
							text: "auto"
							fontSize: Theme.fontSizeSmall
							textColor: Theme.fg
						}
						onClicked: root.pinWifiBand("auto")
					}

					Item { Layout.fillWidth: true }
				}

				RowLayout {
					width: parent.width
					spacing: Theme.roundScaled(8, root.sf)

					ModuleButton {
						accentColor: Theme.accent
						height: Theme.roundScaled(26, root.sf)
						width: Theme.roundScaled(26, root.sf)
						Layout.preferredWidth: Theme.roundScaled(26, root.sf)
						Layout.preferredHeight: Theme.roundScaled(26, root.sf)
						padding: 0
						contentCentered: true
						IconText {
							glyph: "\uf029"
							glyphSize: Theme.roundScaled(14, root.sf)
							glyphColor: Theme.fg
						}
						onClicked: root.showQr()
					}

					Text {
						text: "Compartilhar Wi-Fi (QR)"
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
						color: Theme.stone
						elide: Text.ElideRight
						Layout.fillWidth: true
					}
				}

				Image {
					id: qrImage
					width: Theme.roundScaled(132, root.sf)
					height: Theme.roundScaled(132, root.sf)
					source: root.qrSource
					fillMode: Image.PreserveAspectFit
					visible: root.qrShow
					smooth: true
					anchors.horizontalCenter: parent.horizontalCenter
				}
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