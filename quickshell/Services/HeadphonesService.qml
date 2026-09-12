pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Common
import "../Common/HeadphonesModel.js" as Model

// Battery and noise control for Bluetooth headphones, session-wide.
//
// A bar surface exists per monitor, so the module is built once per screen and
// each copy reads the same service. The Fast Pair reader must exist exactly
// once (BlueZ hands out a single Message Stream registration per system), so it
// lives here, and every follower its lines belong to. Inspired by
// github.com/ncr/omarchy-headphones.
Singleton {
	id: root

	// ---- Settings. Tuned in code for now; a shell.json entry can come later.
	property string deviceMatch: ""
	property bool useFastPair: true
	property bool useModeControl: true
	property int lowThreshold: 20
	property bool notifyLow: true
	property bool pauseOnDisconnect: true

	readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
		|| Quickshell.env("HOME") + "/.local/state")
		+ "/cadrocbar-headphones"

	// ---- Which devices, from BlueZ.
	readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
	readonly property var followedAddresses: Model.followedAddresses(devices, deviceMatch, lastAddress)

	property var followers: []
	readonly property var followed: Model.sortFollowers(followers, lastAddress)
	readonly property var primary: followed.length > 0 ? followed[0] : null

	// Which follower the popup shows. The module sets it on click; a device
	// that has gone falls back to the primary.
	property var current: null
	readonly property var currentDevice: followed.indexOf(current) !== -1 ? current : primary

	readonly property bool anyConnected: {
		for (var i = 0; i < followed.length; i++)
			if (followed[i].connected) return true
		return false
	}

	readonly property string headphonesDir: Theme.binDir + "/headphones"
	readonly property string readerPath: headphonesDir + "/gfps-reader"

	function bridgePathFor(backend) {
		var file = Model.bridgeFor(backend)
		return file === "" ? "" : headphonesDir + "/" + file
	}
	readonly property string jblBridgePath: bridgePathFor("jbl")
	readonly property var readerAddresses: Model.readerAddresses(followed)
	readonly property bool readerRunning: gfpsReader.running

	property bool readerEnabled: true
	property int readerBackoffMs: 8000
	property var readerFollowing: []
	property string readerError: ""
	property string readerRunError: ""

	// ---- Followers, one per followed address, added and removed one at a time
	//      so an untouched row keeps its follower — and with it, its processes.
	ListModel { id: followerRows }

	function syncFollowers() {
		var wanted = followedAddresses
		for (var i = followerRows.count - 1; i >= 0; i--)
			if (wanted.indexOf(followerRows.get(i).deviceAddress) === -1) followerRows.remove(i)
		for (var j = 0; j < wanted.length; j++) {
			var known = false
			for (var k = 0; k < followerRows.count; k++)
				if (followerRows.get(k).deviceAddress === wanted[j]) { known = true; break }
			if (!known) followerRows.append({ deviceAddress: wanted[j] })
		}
	}

	function rebuildFollowers() {
		var list = []
		for (var i = 0; i < followerHost.count; i++) {
			var object = followerHost.objectAt(i)
			if (object) list.push(object)
		}
		followers = list
	}

	onFollowedAddressesChanged: syncFollowers()
	Component.onCompleted: syncFollowers()

	Instantiator {
		id: followerHost
		model: followerRows
		delegate: HeadphonesFollower {
			required property string deviceAddress
			service: root
			address: deviceAddress
		}
		onObjectAdded: root.rebuildFollowers()
		onObjectRemoved: root.rebuildFollowers()
	}

	// ---- The Fast Pair reader: one process, however many devices.
	function applyReaderLine(line) {
		var address = Model.readerLineAddress(line)
		if (address !== "") {
			var follower = followerWithAddress(address)
			if (follower) follower.applyReaderLine(line)
			readerBackoffMs = 8000
			return
		}
		var fields = Model.mergeReaderLine({}, line)
		if (fields.stream === undefined) return
		if (fields.stream === false) {
			readerError = String(fields.error || "")
			readerRunError = readerError
		} else {
			readerError = ""
			readerRunError = ""
			readerBackoffMs = 8000
		}
	}

	function followerWithAddress(address) {
		return Model.deviceByAddress(followers, address)
	}

	function syncReader() {
		if (!gfpsReader.running) return
		var wanted = readerAddresses
		var told = readerFollowing
		for (var i = 0; i < told.length; i++)
			if (wanted.indexOf(told[i]) === -1) gfpsReader.write("unfollow " + told[i] + "\n")
		for (var j = 0; j < wanted.length; j++)
			if (told.indexOf(wanted[j]) === -1) gfpsReader.write("follow " + wanted[j] + "\n")
		readerFollowing = wanted.slice()
	}

	onReaderAddressesChanged: syncReader()

	function refreshReader(address) {
		if (!useFastPair) return false
		if (gfpsReader.running && readerFollowing.indexOf(String(address).toUpperCase()) !== -1) {
			gfpsReader.write("refresh " + address + "\n")
			return true
		}
		readerBackoffMs = 8000
		readerRestart.stop()
		readerEnabled = true
		return false
	}

	readonly property bool readerWanted: root.useFastPair && root.readerAddresses.length > 0
		&& root.readerEnabled
	property bool readerArmed: false
	onReaderWantedChanged: {
		if (!readerWanted) { readerArmed = false; return }
		Qt.callLater(function () { readerArmed = root.readerWanted })
	}

	Process {
		id: gfpsReader
		running: root.readerArmed
		command: [root.readerPath].concat(root.readerAddresses)
		stdinEnabled: true
		stdout: SplitParser {
			onRead: function(line) { root.applyReaderLine(line) }
		}
		stderr: StdioCollector { id: readerStderr; waitForEnd: true }
		onRunningChanged: {
			if (running) {
				root.readerError = ""
				root.readerRunError = ""
				root.readerFollowing = root.readerAddresses.slice()
				for (var i = 0; i < root.followers.length; i++) root.followers[i].clearReaderError()
			} else {
				root.readerFollowing = []
			}
		}
		onExited: function(exitCode, exitStatus) {
			var deliberate = exitCode === 0
			if (!deliberate && root.readerRunError === "")
				root.readerError = Model.shortError(readerStderr.text,
					"the Fast Pair reader stopped (exit " + exitCode + ")")
			root.readerEnabled = false
			readerRestart.interval = deliberate ? 600 : root.readerBackoffMs
			if (!deliberate) root.readerBackoffMs = Math.min(300000, root.readerBackoffMs * 2)
			readerRestart.restart()
		}
	}

	Timer {
		id: readerRestart
		repeat: false
		onTriggered: root.readerEnabled = true
	}

	// ---- Caches the followers share.
	property var modeSupport: ({})
	property var ancParked: ({})
	property var sonyParked: ({})
	property var ancBackoff: ({})

	function ancBackoffFor(key) {
		var value = ancBackoff[String(key)]
		return typeof value === "number" && value > 0 ? value : 10000
	}

	function bumpAncBackoff(key) {
		var next = {}
		for (var name in ancBackoff) next[name] = ancBackoff[name]
		next[String(key)] = Math.min(300000, ancBackoffFor(key) * 2)
		ancBackoff = next
	}

	function resetAncBackoff(key) {
		if (ancBackoff[String(key)] === undefined) return
		var next = {}
		for (var name in ancBackoff) next[name] = ancBackoff[name]
		delete next[String(key)]
		ancBackoff = next
	}

	function parkModel(model) {
		var next = {}
		for (var key in ancParked) next[key] = ancParked[key]
		next[String(model)] = true
		ancParked = next
	}

	function parkAddress(value) {
		if (String(value || "") === "") return
		var next = {}
		for (var key in sonyParked) next[key] = sonyParked[key]
		next[String(value)] = true
		sonyParked = next
	}

	property var notifiedLow: ({})
	function setNotifiedLow(address, value) {
		var key = String(address || "")
		if (key === "") return
		var current = notifiedLow
		if (!current || typeof current !== "object") current = ({})
		if ((current[key] === true) === (value === true)) return
		var next = {}
		for (var name in current) next[name] = current[name]
		if (value) next[key] = true
		else delete next[key]
		notifiedLow = next
	}

	// remembered across a reload is a session convenience: keep the last used
	// address in a plain property. A ConfigFile can take over later.
	property string lastAddress: ""
	function rememberAddress(value) {
		if (lastAddress === value) return
		Qt.callLater(function () { root.lastAddress = value })
	}

	// ---- Notifications: one process, and a queue behind it.
	property var notifyQueue: []

	function notify(title, body) {
		var next = notifyQueue.slice()
		next.push({ title: String(title), body: String(body) })
		notifyQueue = next
		sendNextNotification()
	}

	function sendNextNotification() {
		if (notifyProcess.running || notifyQueue.length === 0) return
		var pending = notifyQueue[0]
		notifyQueue = notifyQueue.slice(1)
		notifyProcess.command = [
			"/usr/bin/notify-send",
			"-u", "critical",
			"-i", "audio-headphones",
			pending.title,
			pending.body
		]
		notifyProcess.running = true
	}

	Process {
		id: notifyProcess
		onExited: root.sendNextNotification()
	}

	// ---- Pause whatever is playing the moment a followed device stops being
	//      available: taken off the ears (wear sensor) or disconnected outright.
	//      Only the players that were actually playing are paused, and their
	//      names are kept, so putting the headset back on resumes exactly those.
	property var pausedPlayers: []

	readonly property var mprisPlayers: MprisService.players

	function isProxyPlayer(player) {
		return String(player.id || "").toLowerCase().indexOf("playerctld") !== -1
	}

	function pauseMedia() {
		if (!pauseOnDisconnect) return
		var paused = []
		var players = mprisPlayers
		for (var i = 0; i < players.length; i++) {
			var p = players[i]
			if (!p || isProxyPlayer(p) || p.status !== "Playing" || !p.canControl) continue
			MprisService.send(p.id, "pause")
			paused.push(String(p.id))
		}
		pausedPlayers = paused
	}

	function resumeMedia() {
		if (!pauseOnDisconnect || pausedPlayers.length === 0) return
		var names = pausedPlayers
		pausedPlayers = []
		var players = mprisPlayers
		for (var i = 0; i < players.length; i++) {
			var p = players[i]
			if (!p || names.indexOf(String(p.id)) < 0 || !p.canControl) continue
			MprisService.send(p.id, "play")
		}
	}

	// ---- Mode cache on disk, remembered across restarts.
	Process {
		id: ensureStateDir
		running: true
		command: ["/usr/bin/mkdir", "-p", root.stateDir]
	}

	FileView {
		id: modeSupportFile
		path: root.stateDir + "/mode-support.json"
		watchChanges: true
		printErrors: false
		onLoaded: root.modeSupport = Model.parseSupport(text())
		onFileChanged: reload()
	}
}