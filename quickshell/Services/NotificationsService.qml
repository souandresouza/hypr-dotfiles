pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.Common
import qs.Widgets

Singleton {
	id: root

	NotificationServer {
		id: server

		bodyMarkupSupported: true
		actionsSupported: true
		actionIconsSupported: true
		bodyHyperlinksSupported: false
		inlineReplySupported: true
		persistenceSupported: true
		keepOnReload: true

		onNotification: (notification) => root.accept(notification)
	}

	property ListModel entries: ListModel {}
	property ListModel toastsModel: ListModel {}
	property var records: ({})

	readonly property int count: entries.count
	readonly property int toastCount: toastsModel.count

	readonly property bool hasUrgent: root.pendingUrgent
	readonly property bool pendingUrgent: {
		for (let i = 0; i < entries.count; i++) {
			const rec = root.records[entries.get(i).id];
			if (rec && rec.urgency === "critical")
				return true;
		}
		return false;
	}

	property bool dndManual: false
	property bool dndFullscreen: true
	property bool fullscreenActive: false

	readonly property bool dnd: root.dndManual || (root.dndFullscreen && root.fullscreenActive)
	onDndChanged: {
		if (!root.dnd)
			root.flushMuted();
	}

	function mayToast(record) {
		if (root.dndManual)
			return false;
		if (root.dndFullscreen && root.fullscreenActive)
			return record.urgency === "critical";
		return true;
	}

	Process {
		id: fullscreenProbe
		stdout: StdioCollector {
			id: fsColl
			waitForEnd: true
		}
		onExited: () => {
			const raw = fsColl.text.toString().trim();
			let fs = 0;
			if (raw.length > 0 && raw.startsWith("{")) {
				try {
					fs = Number(JSON.parse(raw).fullscreen) || 0;
				} catch (e) { /* ignore */ }
			}
			root.fullscreenActive = fs !== 0;
		}
	}

	function probeFullscreen() {
		fullscreenProbe.exec(["hyprctl", "-j", "activewindow"]);
	}

	function flushMuted() {
		const ids = [];
		for (let i = entries.count - 1; i >= 0; i--)
			ids.push(entries.get(i).id);
		for (const id of ids) {
			const rec = root.records[id];
			if (rec && rec.muted) {
				rec.muted = false;
				root.popToast(rec);
			}
		}
	}

	readonly property int toastWidth: 320

	function recordById(id) {
		return root.records[id];
	}

	function urgencyOf(u) {
		if (u === NotificationUrgency.Critical)
			return "critical";
		if (u === NotificationUrgency.Low)
			return "low";
		return "normal";
	}

	function listActions(actions) {
		const arr = [];
		for (let i = 0; i < actions.length; i++)
			arr.push({ identifier: actions[i].identifier, text: actions[i].text });
		return arr;
	}

	function appGlyph(appName) {
		const n = (appName || "").toLowerCase();
		if (n.includes("telegram") || n.includes("whatsapp") || n.includes("discord")
			|| n.includes("slack") || n.includes("signal") || n.includes("matrix"))
			return "\uf086";
		if (n.includes("firefox") || n.includes("browser") || n.includes("chrom"))
			return "\uf0ac";
		if (n.includes("spotify") || n.includes("music") || n.includes("mpv")
			|| n.includes("vlc") || n.includes("mpris"))
			return "\uf001";
		if (n.includes("kitty") || n.includes("terminal") || n.includes("shell"))
			return "\uf120";
		if (n.includes("mail") || n.includes("thunderbird") || n.includes("evolution"))
			return "\uf0e0";
		return "\uf0a1";
	}

	function fmtTime(ts) {
		const d = new Date(ts);
		const h = d.getHours().toString().padStart(2, "0");
		const m = d.getMinutes().toString().padStart(2, "0");
		return h + ":" + m;
	}

	function lifetimeFor(entry) {
		if (entry.urgency === "critical")
			return 0;
		if (entry.transient)
			return 6000;
		return 10000;
	}

	function accept(notification) {
		const now = Date.now();
		const id = notification.id;

		if (root.records[id]) {
			const rec = root.records[id];
			rec.notif = notification;
			notification.tracked = true;
			notification.closed.connect(() => root.dropNotif(notification));
			return;
		}

		while (entries.count >= 40) {
			const stale = root.records[entries.get(entries.count - 1).id];
			if (stale)
				stale.notif.dismiss();
		}

		const record = {
			notif: notification,
			appName: notification.appName,
			appIcon: notification.appIcon,
			image: notification.image,
			summary: notification.summary,
			body: notification.body,
			urgency: root.urgencyOf(notification.urgency),
			transient: notification.transient,
			actions: root.listActions(notification.actions),
			hasInlineReply: notification.hasInlineReply,
			placeholder: notification.inlineReplyPlaceholder,
time: now,
		toasting: false,
		muted: false,
		leaving: false,
			leaveAt: 0,
			lifetime: 0,
			expireOnClose: false
		};

		notification.tracked = true;
		notification.closed.connect(() => root.dropNotif(notification));
		root.records[id] = record;
		entries.insert(0, { id: id });

		if (!notification.lastGeneration) {
			if (root.mayToast(record)) {
				root.popToast(record);
			} else {
				record.muted = true;
			}
		}
	}

	function dropNotif(notification) {
		let recId = -1;
		for (const id in root.records) {
			if (root.records[id].notif === notification) {
				recId = Number(id);
				break;
			}
		}
		if (recId < 0)
			return;

		for (let j = 0; j < root.toastsModel.count; j++) {
			if (root.toastsModel.get(j).id === recId) {
				root.toastsModel.remove(j);
				break;
			}
		}
		for (let i = 0; i < entries.count; i++) {
			if (entries.get(i).id === recId) {
				entries.remove(i);
				break;
			}
		}
		delete root.records[recId];
	}

	function popToast(record) {
		if (record.toasting)
			return;
		record.toasting = true;
		record.lifetime = root.lifetimeFor(record);
		while (root.toastsModel.count >= 5) {
			const firstId = root.toastsModel.get(0).id;
			const first = root.records[firstId];
			root.toastsModel.remove(0);
			if (first)
				first.notif.dismiss();
		}
		root.toastsModel.insert(0, { id: record.notif.id });
	}

	function closeEntry(record) {
		if (!record || record.leaving)
			return;
		record.leaving = true;
		record.leaveAt = Date.now() + 180;
		record.expireOnClose = false;
	}

	function clearAll() {
		for (let i = entries.count - 1; i >= 0; i--) {
			const rec = root.records[entries.get(i).id];
			if (rec)
				rec.notif.dismiss();
		}
	}

	function sweep() {
		const now = Date.now();
		for (let i = root.toastsModel.count - 1; i >= 0; i--) {
			const t = root.records[root.toastsModel.get(i).id];
			if (!t)
				continue;
			if (t.leaving) {
				if (now < t.leaveAt)
					continue;
				root.toastsModel.remove(i);
				if (t.expireOnClose)
					t.notif.expire();
				else
					t.notif.dismiss();
				continue;
			}
			if (t.lifetime > 0 && now - t.time >= t.lifetime) {
				t.leaving = true;
				t.leaveAt = now + 180;
				t.expireOnClose = true;
			}
		}
	}

	Timer {
		interval: 400
		repeat: true
		running: true
		onTriggered: root.sweep()
	}

	Timer {
		interval: 1500
		repeat: true
		running: root.dndFullscreen
		onTriggered: root.probeFullscreen()
	}

	Component.onCompleted: root.probeFullscreen()

	IpcHandler {
		target: "notifications"

		function clear() {
			root.clearAll();
		}

		function closeToasts() {
			for (let i = root.toastsModel.count - 1; i >= 0; i--) {
				const rec = root.records[root.toastsModel.get(i).id];
				if (rec)
					root.closeEntry(rec);
			}
		}

		function toggleDnd() {
			root.dndManual = !root.dndManual;
		}

		function dnd(val: string) {
			root.dndManual = /^(on|true|1|yes)$/i.test(String(val));
		}
	}

	PanelWindow {
		id: toastWindow
		visible: root.toastCount > 0
		color: "transparent"

		implicitWidth: root.toastWidth + 12
		implicitHeight: toastTopMargin + toastList.contentHeight + 8

		WlrLayershell.namespace: "cadrocbar:notifications"
		WlrLayershell.layer: WlrLayershell.Overlay
		WlrLayershell.exclusiveZone: 0
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

		anchors {
			top: true
			right: true
		}

		property int toastTopMargin: Theme.barHeight + Theme.barTopMargin + Theme.popupGap + 4

		ListView {
			id: toastList
			anchors.top: toastWindow.top
			anchors.right: toastWindow.right
			anchors.topMargin: toastWindow.toastTopMargin
			anchors.rightMargin: 12
			width: root.toastWidth
			spacing: 8
			interactive: false
			model: root.toastsModel

			delegate: NotificationCard {
				width: root.toastWidth
				toast: true
			}
		}
	}
}