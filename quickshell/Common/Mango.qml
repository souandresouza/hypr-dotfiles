pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: mango

	property bool available: false
	property var monitors: []
	readonly property var byName: (() => {
			const map = {};
			for (const m of monitors) {
				map[m.name] = m;
			}
			return map;
		})()

	signal changed

	function monitorForScreen(screen) {
		if (!screen)
			return undefined;
		return byName[screen.name];
	}

	function tagsForScreen(screen) {
		const m = monitorForScreen(screen);
		return m ? m.tags : [];
	}

	function tagCount(screen) {
		const m = monitorForScreen(screen);
		return m ? (m.tag_num || m.tags?.length || 0) : 0;
	}

	function focusedForScreen(screen) {
		const m = monitorForScreen(screen);
		return m ? m.active_client : null;
	}

	function dispatch(tagIndex) {
		Quickshell.execDetached(["mmsg", "dispatch", "view," + tagIndex]);
	}

	function refresh() {
		mangoProcess.exec(["mmsg", "get", "all-monitors"]);
	}

	Timer {
		id: pollTimer
		interval: 500
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: mango.refresh()
	}

	Process {
		id: mangoProcess

		running: false
		stdout: StdioCollector {
			id: collector
			waitForEnd: true
		}

		onExited: (exitCode) => {
			mango.available = exitCode === 0;
			const line = collector.text.toString().trim();
			if (line.length === 0)
				return;
			try {
				const parsed = JSON.parse(line);
				if (parsed.monitors !== undefined)
					mango.monitors = parsed.monitors;
				mango.changed();
			} catch (e) { console.warn("[mango] falha ao parsear output:", e.message); }
		}
	}
}