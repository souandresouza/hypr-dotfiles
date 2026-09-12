import QtQuick
import Quickshell
import Quickshell.Io
import "../Common/HeadphonesModel.js" as Model

// One device, followed for as long as it is connected.
//
// Everything here belongs to a single set of earbuds: its mode bridge, its
// levels, its errors, its warning state. The address is handed in when the
// service builds this and never changes afterwards. The Fast Pair reader is
// the one helper a follower does not own — the service holds it and routes
// lines by address.
Item {
	id: follower

	property var service: null
	property string address: ""

	readonly property var device: Model.deviceByAddress(service ? service.devices : [], address)

	readonly property bool hasDevice: !!device
	readonly property bool connected: hasDevice && device.connected === true
	readonly property string name: hasDevice ? Model.deviceLabel(device) : ""
	readonly property string reportedName: hasDevice
		? (Model.plainText(device.deviceName).trim() || name) : ""

	readonly property bool useFastPair: service ? service.useFastPair : true
	readonly property bool useModeControl: service ? service.useModeControl : true
	readonly property int lowThreshold: service ? service.lowThreshold : 20
	readonly property bool notifyLow: service ? service.notifyLow : true

	// ---- What the service's Fast Pair reader said about this device.
	property var reading: ({})
	property bool refreshing: false
	property real readingStamp: 0
	property string readerErrorRaw: ""
	readonly property bool readerRunning: service ? service.readerRunning : false
	readonly property string serviceReaderError: service ? service.readerError : ""
	readonly property string readerError: !useFastPair
		? ""
		: (readerErrorRaw !== "" ? readerErrorRaw : serviceReaderError)

	readonly property bool streaming: reading.stream === true
		&& (readerRunning || refreshing)

	// Battery from the mode bridge, on a device whose control channel carries
	// it (Nothing). Second to the Fast Pair stream.
	readonly property bool bridgeBattery: ancLive && !streaming
		&& (Model.bridgeLevel(ancState, "left") >= 0 || Model.bridgeLevel(ancState, "right") >= 0
		    || Model.bridgeLevel(ancState, "case") >= 0 || Model.bridgeLevel(ancState, "headset") >= 0)

	readonly property int leftLevel: streaming ? Model.readerLevel(reading, "left")
		: (bridgeBattery ? Model.bridgeLevel(ancState, "left") : -1)
	readonly property int rightLevel: streaming ? Model.readerLevel(reading, "right")
		: (bridgeBattery ? Model.bridgeLevel(ancState, "right") : -1)
	readonly property int caseLevel: streaming ? Model.readerLevel(reading, "case")
		: (bridgeBattery ? Model.bridgeLevel(ancState, "case") : -1)
	readonly property bool leftCharging: streaming ? reading.leftCharging === true
		: (bridgeBattery && Model.bridgeCharging(ancState, "left"))
	readonly property bool rightCharging: streaming ? reading.rightCharging === true
		: (bridgeBattery && Model.bridgeCharging(ancState, "right"))
	readonly property bool caseCharging: streaming ? reading.caseCharging === true
		: (bridgeBattery && Model.bridgeCharging(ancState, "case"))
	readonly property bool perBud: leftLevel >= 0 || rightLevel >= 0
	readonly property bool caseStale: bridgeBattery && Model.bridgeCaseStale(ancState)

	readonly property bool single: streaming ? reading.single === true
		: (bridgeBattery && Model.bridgeLevel(ancState, "headset") >= 0)
	readonly property int singleLevel: !single ? -1
		: (streaming ? Model.readerLevel(reading, "battery") : Model.bridgeLevel(ancState, "headset"))
	readonly property bool singleCharging: single && (streaming ? reading.batteryCharging === true
		: Model.bridgeCharging(ancState, "headset"))

	readonly property string modelId: String(reading.modelId || "")
	readonly property string bleAddress: String(reading.bleAddress || "")

	// The backend is picked from the device's SDP UUIDs (a Classic channel the
	// device itself serves) or, for JBL, from a BLE address the Fast Pair
	// stream announced.
	property var deviceUuids: []
	readonly property string controlBackend: Model.controlBackend(deviceUuids, bleAddress)
	readonly property bool classicBackend: Model.isClassicBackend(controlBackend)
	readonly property string sonyUuid: controlBackend === "sony" ? Model.sonyUuidFor(deviceUuids) : ""

	readonly property string jblBridgePath: service ? service.jblBridgePath : ""
	readonly property string classicBridgePath: service && classicBackend
		? service.bridgePathFor(controlBackend) : ""
	property var ancState: ({})
	property bool ancEnabled: true
	readonly property bool jblWanted: useModeControl && useFastPair && ancEnabled && connected
		&& controlBackend === "jbl"
		&& bleAddress !== ""
		&& modeSupportKnown !== 0
		&& !ancModelParked
	property bool jblArmed: false
	onJblWantedChanged: {
		if (!jblWanted) { jblArmed = false; return }
		Qt.callLater(function () { jblArmed = follower.jblWanted })
	}
	property bool ancRestartWanted: false
	property bool ancAnswered: false
	property string ancRunError: ""
	property string ancErrorRaw: ""
	property bool classicEnabled: true
	readonly property bool classicWanted: useModeControl && classicEnabled && connected
		&& classicBridgePath !== ""
		&& !addressParked
	property bool classicArmed: false
	onClassicWantedChanged: {
		if (!classicWanted) { classicArmed = false; return }
		Qt.callLater(function () { classicArmed = follower.classicWanted })
	}

	readonly property bool ancSupported: ancState.modes === true
	readonly property string ancMode: String(ancState.mode || "")
	readonly property var modesAvailable: Model.modesAvailable(ancState)
	readonly property var ancLevels: Model.ancLevelsAvailable(ancState)
	readonly property string ancLevel: Model.ancLevel(ancState)
	readonly property bool latencyKnown: ancLive && typeof ancState.latency === "boolean"
	readonly property bool latencyEnabled: latencyKnown && ancState.latency === true
	readonly property int ambientLevel: typeof ancState.level === "number" ? ancState.level : -1
	readonly property bool ambientVoice: ancState.voice === true
	readonly property bool ambientControls: ancLive && ambientLevel >= 0
	readonly property bool wearSupported: ancState.worn !== undefined
	readonly property bool worn: ancState.worn !== false

	readonly property bool bridgeRunning: ancBridge.running || classicBridge.running
	readonly property bool ancLive: bridgeRunning && ancAnswered
	readonly property string ancError: {
		if (!useModeControl) return ""
		if (!classicBackend && !useFastPair)
			return "needs Fast Pair for the BLE address"
		return ancErrorRaw
	}

	readonly property int modeSupportKnown: Model.supportVerdict(service ? service.modeSupport : ({}), modelId)
	readonly property bool ancModelParked: service ? service.ancParked[modelId] === true : false
	readonly property bool addressParked: service ? service.sonyParked[address] === true : false
	readonly property string ancBackoffKey: classicBackend ? address : modelId

	readonly property var ambientRange: Model.ambientRange(controlBackend)
	readonly property int ambientMin: ambientRange.min
	readonly property int ambientMax: ambientRange.max
	readonly property string ambientVoiceLabel: ambientRange.voice

	readonly property int bluezLevel: Model.batteryLevel(device)
	readonly property int level: singleLevel >= 0
		? singleLevel
		: (perBud ? Model.lowestBud(leftLevel, rightLevel) : bluezLevel)
	readonly property bool charging: leftCharging || rightCharging || singleCharging
	readonly property bool low: connected && level >= 0 && level <= lowThreshold && !charging

	readonly property var summary: ({
		hasDevice: follower.hasDevice, connected: follower.connected, name: follower.name,
		level: follower.level, left: follower.leftLevel, right: follower.rightLevel,
		caseLevel: follower.caseLevel,
		single: follower.single, singleLevel: follower.singleLevel
	})

	readonly property int stalerThanMs: 30000

	property string lastSource: ""
	property int lastLevel: -1
	property bool primed: false
	property bool sawDisconnected: false

	readonly property bool notifiedLow: service && service.notifiedLow
		? service.notifiedLow[address] === true : false
	function setNotifiedLow(value) {
		if (service) service.setNotifiedLow(address, value)
	}

	function readerLineFields(line) {
		var parsed = null
		try {
			parsed = JSON.parse(String(line || "").trim() || "{}")
		} catch (e) {
			return ({})
		}
		if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return ({})
		return parsed
	}

	function applyReaderLine(line) {
		var incoming = readerLineFields(line)
		var next = Model.mergeReaderLine(reading, line)
		reading = next
		if (next.stream === false) readerErrorRaw = String(next.error || "")
		else readerErrorRaw = ""
		if (incoming.left !== undefined || incoming.right !== undefined
		    || incoming.battery !== undefined) {
			readingStamp = Date.now()
			refreshing = false
		}
	}

	function applyAncLine(line) {
		var parsed = null
		try {
			parsed = JSON.parse(String(line || "").trim() || "{}")
		} catch (e) {
			return
		}
		if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) return
		var carried = ["available", "level", "voice", "worn",
		               "ancLevel", "ancLevels", "latency", "battery"]
		for (var i = 0; i < carried.length; i++) {
			var key = carried[i]
			if (parsed[key] === undefined && ancState[key] !== undefined) parsed[key] = ancState[key]
		}
		var wasWorn = ancState.worn
		ancState = parsed
		if (service) {
			if (wasWorn === true && parsed.worn === false) service.pauseMedia()
			else if (wasWorn === false && parsed.worn === true) service.resumeMedia()
		}
		if (parsed.modes === true) {
			ancAnswered = true
			ancErrorRaw = ""
			if (service) service.resetAncBackoff(ancBackoffKey)
		} else if (parsed.error !== undefined) {
			ancRunError = String(parsed.error || "")
			ancErrorRaw = ancRunError
		}
	}

	function probeUuids() {
		if (!connected || address === "") {
			deviceUuids = []
			return
		}
		if (uuidProbe.running) return
		uuidProbe.command = ["/usr/bin/bluetoothctl", "info", address]
		uuidProbe.running = true
	}

	function refresh() {
		if (!connected) return
		readerErrorRaw = ""
		if (service) {
			service.resetAncBackoff(modelId)
			service.resetAncBackoff(address)
		}
		if (ancRestart.running) { ancRestart.stop(); ancEnabled = true }
		if (classicRestart.running) { classicRestart.stop(); classicEnabled = true }
		if (!useFastPair || !service) return
		if (service.refreshReader(address)) {
			refreshing = true
			refreshGuard.restart()
		}
	}

	function clearReaderError() {
		readerErrorRaw = ""
	}

	function refreshIfStale() {
		if (!connected) return
		if (readingStamp === 0 || Date.now() - readingStamp > stalerThanMs) refresh()
	}

	function classicLive(backend) {
		return ancLive && classicBridge.running && controlBackend === backend
	}

	function setAncMode(mode) {
		if (!ancSupported || !ancLive) return false
		if (modesAvailable.indexOf(String(mode)) === -1) return false
		if (classicBridge.running) classicBridge.write("set " + mode + "\n")
		else ancBridge.write("set " + mode + "\n")
		return true
	}

	function setAmbientLevel(value) {
		if (!classicLive("sony") && !classicLive("soundcore")) return false
		var level = Math.max(ambientMin, Math.min(ambientMax, Math.round(Number(value))))
		if (!isFinite(level)) return false
		classicBridge.write("level " + level + "\n")
		return true
	}

	function setAmbientVoice(on) {
		if (classicLive("soundcore")) {
			classicBridge.write("wind " + (on ? "on" : "off") + "\n")
			return true
		}
		if (!classicLive("sony")) return false
		classicBridge.write("voice " + (on ? "on" : "off") + "\n")
		return true
	}

	function setAncLevel(level) {
		if (!ancLive || !classicBridge.running) return false
		if (ancLevels.indexOf(String(level)) === -1) return false
		classicBridge.write("level " + level + "\n")
		return true
	}

	function setLatency(on) {
		if (!latencyKnown || !classicBridge.running) return false
		classicBridge.write("latency " + (on ? "on" : "off") + "\n")
		return true
	}

	function bounceAncBridge() {
		if (ancBridge.running) {
			ancRestartWanted = true
			ancEnabled = false
			return
		}
		ancRestart.stop()
		ancEnabled = true
	}

	function checkLowBattery() {
		if (!notifyLow) return
		if (!connected) {
			setNotifiedLow(false)
			forgetLevelHistory()
			return
		}
		if (level < 0) return

		var source = single ? "single" : (perBud ? "bud" : "bluez")
		var previous = source === lastSource ? lastLevel : -1
		lastSource = source
		lastLevel = level

		if (level >= lowThreshold + 5 || charging) setNotifiedLow(false)
		if (charging) return

		if (!primed) {
			primed = true
			return
		}

		if (level > lowThreshold || notifiedLow) return
		var dropped = previous >= 0 && level < previous
		var firstSinceConnect = previous < 0
		if (!dropped && !firstSinceConnect) return

		setNotifiedLow(true)
		Qt.callLater(sendLowBatteryWarning)
	}

	function sendLowBatteryWarning() {
		if (!connected || level < 0 || !service) return
		service.notify(follower.name + " battery low", Model.lowBatteryBody(follower.summary))
	}

	function forgetLevelHistory() {
		lastSource = ""
		lastLevel = -1
	}

	onLevelChanged: checkLowBattery()
	onChargingChanged: checkLowBattery()
	onLowThresholdChanged: checkLowBattery()

	onConnectedChanged: {
		if (connected && address !== "" && service) service.rememberAddress(address)
		if (connected && sawDisconnected) primed = true
		if (!connected) {
			if (hasDevice) sawDisconnected = true
			if (service) service.pauseMedia()
			setNotifiedLow(false)
			forgetLevelHistory()
			reading = ({})
			readingStamp = 0
			readerErrorRaw = ""
			ancState = ({})
			ancAnswered = false
			deviceUuids = []
		}
		if (connected) probeUuids()
		checkLowBattery()
	}

	onHasDeviceChanged: if (hasDevice && !connected) sawDisconnected = true

	Component.onCompleted: {
		if (connected && address !== "" && service) service.rememberAddress(address)
		probeUuids()
		checkLowBattery()
	}

	Timer {
		id: refreshGuard
		interval: 12000
		repeat: false
		onTriggered: follower.refreshing = false
	}

	Process {
		id: ancBridge
		running: follower.jblArmed
		command: [follower.jblBridgePath].concat(Model.bridgeArgs("jbl",
			{ bleAddress: follower.bleAddress, modelId: follower.modelId }))
		stdinEnabled: true
		stdout: SplitParser {
			onRead: function(line) { follower.applyAncLine(line) }
		}
		stderr: StdioCollector { id: ancStderr; waitForEnd: true }
		onRunningChanged: {
			if (running) {
				follower.ancRunError = ""
				follower.ancErrorRaw = ""
			}
			follower.ancState = ({})
			follower.ancAnswered = false
		}
		onExited: function(exitCode, exitStatus) {
			if (exitCode === 3 && follower.modelId !== "" && follower.service)
				follower.service.parkModel(follower.modelId)
			if (exitCode === 3) {
				follower.ancRunError = ""
				follower.ancErrorRaw = ""
			} else if (exitCode !== 0 && follower.ancRunError === "") {
				follower.ancErrorRaw = Model.shortError(ancStderr.text, exitCode === 4
					? "the listening-mode bridge could not start"
					: "the listening-mode link dropped (exit " + exitCode + ")")
			}

			var deliberate = follower.ancRestartWanted
			follower.ancRestartWanted = false
			follower.ancEnabled = false
			ancRestart.interval = deliberate ? 600
				: (follower.service ? follower.service.ancBackoffFor(follower.modelId) : 10000)
			if (!deliberate && (exitCode === 1 || exitCode === 4) && follower.service)
				follower.service.bumpAncBackoff(follower.modelId)
			ancRestart.restart()
		}
	}

	Timer {
		id: ancRestart
		repeat: false
		onTriggered: follower.ancEnabled = true
	}

	Process {
		id: classicBridge
		running: follower.classicArmed
		command: follower.classicBridgePath === ""
			? ["true"]
			: [follower.classicBridgePath].concat(Model.bridgeArgs(follower.controlBackend, {
				address: follower.address, uuid: follower.sonyUuid, name: follower.reportedName }))
		stdinEnabled: true
		stdout: SplitParser {
			onRead: function(line) { follower.applyAncLine(line) }
		}
		stderr: StdioCollector { id: classicStderr; waitForEnd: true }
		onRunningChanged: {
			if (running) {
				follower.ancRunError = ""
				follower.ancErrorRaw = ""
			}
			follower.ancState = ({})
			follower.ancAnswered = false
		}
		onExited: function(exitCode, exitStatus) {
			if (exitCode === 3 && follower.service)
				follower.service.parkAddress(follower.address)
			if (exitCode === 3) {
				follower.ancRunError = ""
				follower.ancErrorRaw = ""
			} else if (exitCode !== 0 && follower.ancRunError === "") {
				follower.ancErrorRaw = Model.shortError(classicStderr.text, exitCode === 4
					? "the listening-mode bridge could not start"
					: "the listening-mode link dropped (exit " + exitCode + ")")
			}

			follower.classicEnabled = false
			classicRestart.interval = follower.service
				? follower.service.ancBackoffFor(follower.address) : 10000
			if ((exitCode === 1 || exitCode === 4) && follower.service)
				follower.service.bumpAncBackoff(follower.address)
			classicRestart.restart()
		}
	}

	Timer {
		id: classicRestart
		repeat: false
		onTriggered: follower.classicEnabled = true
	}

	Process {
		id: uuidProbe
		stdout: StdioCollector { id: uuidProbeOut; waitForEnd: true }
		onExited: function(exitCode, exitStatus) {
			follower.deviceUuids = exitCode === 0
				? Model.uuidsFromBluetoothctl(uuidProbeOut.text)
				: []
		}
	}

	onBleAddressChanged: if (bleAddress !== "") bounceAncBridge()
}