import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import "../Common/HeadphonesModel.js" as Model

// Popup for the Headphones module: per-earbud/case battery and, where the
// device's own channel carries it, the noise-control row (Off / ANC / Ambient /
// TalkThru) plus the ambient dial and switches the brand offers.
Item {
	id: root

	property real sf: 1

	readonly property var service: HeadphonesService
	readonly property var current: service.currentDevice

	// Pull the follower's state through small property aliases so the bindings
	// below read like the feature, not like an object graph.
	readonly property bool hasDevice: current ? current.hasDevice : false
	readonly property bool connected: current ? current.connected : false
	readonly property string deviceName: current ? current.name : "Headphones"

	readonly property int leftLevel: current ? current.leftLevel : -1
	readonly property int rightLevel: current ? current.rightLevel : -1
	readonly property int caseLevel: current ? current.caseLevel : -1
	readonly property bool leftCharging: current ? current.leftCharging : false
	readonly property bool rightCharging: current ? current.rightCharging : false
	readonly property bool caseCharging: current ? current.caseCharging : false
	readonly property bool perBud: current ? current.perBud : false
	readonly property bool single: current ? current.single : false
	readonly property int singleLevel: current ? current.singleLevel : -1
	readonly property bool singleCharging: current ? current.singleCharging : false
	readonly property int bluezLevel: current ? current.bluezLevel : -1
	readonly property bool levelKnown: single || perBud || bluezLevel >= 0

	readonly property bool ancSupported: current ? current.ancSupported : false
	readonly property string ancMode: current ? current.ancMode : ""
	readonly property string ancError: current ? current.ancError : ""
	readonly property var modesAvailable: current ? current.modesAvailable : []
	readonly property int ambientLevel: current ? current.ambientLevel : -1
	readonly property bool ambientVoice: current ? current.ambientVoice : false
	readonly property bool ambientControls: current ? current.ambientControls : false
	readonly property int ambientMin: current ? current.ambientMin : 0
	readonly property int ambientMax: current ? current.ambientMax : 20
	readonly property string ambientVoiceLabel: current ? current.ambientVoiceLabel : "Focus on voice"
	readonly property var ancLevels: current ? current.ancLevels : []
	readonly property string ancLevel: current ? current.ancLevel : ""
	readonly property bool latencyKnown: current ? current.latencyKnown : false
	readonly property bool latencyEnabled: current ? current.latencyEnabled : false
	readonly property string readerError: current ? current.readerError : ""

	readonly property string statusText: current
		? Model.statusLine(current.summary) : "no headphones paired"

	// ---- The modes this device offers, in fixed order, for the button row.
	readonly property var modeOptions: [
		{ value: "off", label: "Off" },
		{ value: "anc", label: "ANC" },
		{ value: "ambient", label: "Ambient" },
		{ value: "talkthru", label: "TalkThru" }
	]
	readonly property var offeredModes: {
		var out = []
		for (var i = 0; i < modeOptions.length; i++)
			if (modesAvailable.indexOf(modeOptions[i].value) !== -1)
				out.push(modeOptions[i])
		return out
	}
	readonly property bool modeRowVisible: service.useModeControl && ancSupported && offeredModes.length > 0

	readonly property var levelOptions: {
		var out = []
		for (var i = 0; i < ancLevels.length; i++)
			out.push({ value: ancLevels[i], label: capital(ancLevels[i]) })
		return out
	}

	function capital(word) {
		if (!word) return ""
		return word.charAt(0).toUpperCase() + word.slice(1)
	}

	Column {
		anchors.fill: parent
		anchors.margins: Theme.roundScaled(14, root.sf)
		spacing: Theme.roundScaled(10, root.sf)

		// ---- Header
		Item {
			width: parent.width
			height: Theme.roundScaled(34, root.sf)

			Text {
				id: nameText
				text: root.deviceName
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeLarge, root.sf)
				font.weight: Font.Bold
				color: Theme.fg
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				elide: Text.ElideRight
				width: parent.width - glyphBox.width - Theme.roundScaled(8, root.sf)
			}

			Item {
				id: glyphBox
				width: Theme.roundScaled(26, root.sf)
				height: Theme.roundScaled(26, root.sf)
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter

				Text {
					anchors.centerIn: parent
					text: "\uf02cb"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(24, root.sf)
					color: root.connected
						? (root.current && root.current.low ? Theme.danger : Theme.fg)
						: Qt.rgba(Theme.sage.r, Theme.sage.g, Theme.sage.b, 0.55)
				}
			}
		}

		Text {
			text: root.statusText
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
			color: Theme.stone
			height: Theme.roundScaled(16, root.sf)
			verticalAlignment: Text.AlignVCenter
		}

		Rectangle {
			width: parent.width
			height: 1
			color: Theme.popupBorder
		}

		// ---- Battery rows
		Column {
			width: parent.width
			spacing: Theme.roundScaled(6, root.sf)

			// Single-battery headset.
			BatteryRow {
				visible: root.single
				label: "Battery"
				level: root.singleLevel
				charging: root.singleCharging
				sf: root.sf
			}

			// Per-earbud.
			BatteryRow {
				visible: root.perBud
				label: "Left"
				level: root.leftLevel
				charging: root.leftCharging
				sf: root.sf
			}
			BatteryRow {
				visible: root.perBud
				label: "Right"
				level: root.rightLevel
				charging: root.rightCharging
				sf: root.sf
			}
			BatteryRow {
				visible: root.perBud
				label: "Case"
				level: root.caseLevel
				charging: false
				sf: root.sf
			}

			// BlueZ fallback.
			BatteryRow {
				visible: !root.single && !root.perBud && root.bluezLevel >= 0
				label: "Battery"
				level: root.bluezLevel
				charging: false
				sf: root.sf
			}

			Text {
				visible: root.connected && !root.levelKnown && root.readerError === ""
				text: "Awaiting battery report \u2026"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.stone
			}

			Text {
				visible: root.connected && root.readerError !== ""
				text: root.readerError
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.sage
				wrapMode: Text.WordWrap
			}
		}

		// ---- Noise control row
		Column {
			width: parent.width
			visible: root.modeRowVisible
			spacing: Theme.roundScaled(6, root.sf)

			Text {
				text: "MODE"
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.sage
			}

			RowLayout {
				width: parent.width
				spacing: Theme.roundScaled(6, root.sf)

				Repeater {
					model: root.offeredModes
					delegate: ModeButton {
						required property var modelData
						label: modelData.label
						active: root.ancMode === modelData.value
						sf: root.sf
						onPressed: current.setAncMode(modelData.value)
					}
				}
			}

			// ANC strength (Nothing / CMF).
			Column {
				width: parent.width
				visible: root.levelOptions.length > 0
				spacing: Theme.roundScaled(4, root.sf)

				Text {
					text: "ANC level"
					font.family: Theme.fontFamily
					font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
					color: Theme.stone
				}

				RowLayout {
					width: parent.width
					spacing: Theme.roundScaled(6, root.sf)

					Repeater {
						model: root.levelOptions
						delegate: ModeButton {
							required property var modelData
							label: modelData.label
							active: root.ancMode === "anc" && root.ancLevel === modelData.value
							sf: root.sf
							onPressed: current.setAncLevel(modelData.value)
						}
					}
				}
			}

			// Ambient dial (Sony 0-20, Soundcore 1-5) + voice/wind switch.
			Column {
				width: parent.width
				visible: root.ambientControls
				spacing: Theme.roundScaled(4, root.sf)

				HSlider {
					width: parent.width
					sf: root.sf
					minimum: root.ambientMin
					maximum: root.ambientMax
					value: root.ambientLevel >= 0 ? root.ambientLevel : root.ambientMin
					onValuePushed: (v) => { if (current) current.setAmbientLevel(v) }
				}

				ToggleRow {
					width: parent.width
					sf: root.sf
					glyph: "\uf075"
					label: root.ambientVoiceLabel
					value: root.ambientVoice ? "on" : "off"
					glyphColor: Theme.accent
					active: root.ambientVoice
					onToggled: { if (current) current.setAmbientVoice(!root.ambientVoice) }
				}
			}

			// Low latency switch (Nothing / CMF).
			ToggleRow {
				width: parent.width
				sf: root.sf
				visible: root.latencyKnown
				glyph: "\uf017"
				label: "Low latency"
				value: root.latencyEnabled ? "on" : "off"
				glyphColor: Theme.accent
				active: root.latencyEnabled
				onToggled: { if (current) current.setLatency(!root.latencyEnabled) }
			}

			Text {
				visible: root.connected && !root.modeRowVisible && root.ancError !== ""
				text: "Mode \u00b7 " + root.ancError
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.sf)
				color: Theme.sage
				wrapMode: Text.WordWrap
			}
		}
	}

	// ---- One mode/strength button on the mode row.
	component ModeButton: Item {
		id: btn
		property string label: ""
		property bool active: false
		property real sf: 1
		signal pressed

		height: Theme.roundScaled(28, btn.sf)
		Layout.fillWidth: true
		Layout.preferredWidth: 0

		Rectangle {
			anchors.fill: parent
			radius: Theme.moduleRadius
			color: btn.active
				? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
				: Theme.moduleHover
			border.width: 1
			border.color: btn.active ? Theme.accent : Theme.popupBorder
		}

		Text {
			anchors.centerIn: parent
			text: btn.label
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, btn.sf)
			color: btn.active ? Theme.fg : Theme.stone
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: btn.pressed()
		}
	}

	// ---- One battery row: label, level, charging bolt and meter.
	component BatteryRow: Item {
		id: brow
		property string label: ""
		property int level: -1
		property bool charging: false
		property real sf: 1

		height: Theme.roundScaled(30, brow.sf)

		Text {
			text: brow.label
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSize, brow.sf)
			color: brow.level < 0 ? Theme.sage : Theme.fg
			anchors.left: parent.left
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			text: brow.level < 0 ? "\u2014" : brow.level + "%" + (brow.charging ? " \uf0e7" : "")
			font.family: Theme.fontFamily
			font.pixelSize: Theme.roundScaled(Theme.fontSize, brow.sf)
			color: brow.level >= 0 && brow.level <= 20 && !brow.charging
				? Theme.danger : Theme.fg
		}

		Rectangle {
			id: meterTrack
			height: 4
			radius: 2
			width: Theme.roundScaled(120, brow.sf)
			color: Theme.moduleHover
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 2
			visible: brow.level >= 0
		}

		Rectangle {
			width: meterTrack.width * Math.max(0, Math.min(1, brow.level / 100))
			height: meterTrack.height
			radius: meterTrack.radius
			color: brow.level <= 20 && !brow.charging ? Theme.danger : Theme.accent
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 2
			visible: brow.level >= 0
		}
	}
}