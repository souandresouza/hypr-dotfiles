pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: backlight

	property int percent: 0
	property int max: 0
	property int current: 0
	property bool available: false
	signal changed

	Timer {
		id: pollTimer
		interval: 2000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: blProcess.exec([Theme.binDir + "/backlight.sh", "get"])
	}

	Process {
		id: blProcess

		running: false
		stdout: StdioCollector {
			id: coll
			waitForEnd: true
		}

		onExited: () => {
			const line = coll.text.toString().trim();
			if (line.length === 0)
				return;
			try {
				const j = JSON.parse(line);
				backlight.current = Number(j.cur) || 0;
				backlight.max = Number(j.max) || 0;
				backlight.percent = Number(j.pct) || 0;
				backlight.available = backlight.current > 0;
				backlight.changed();
			} catch (e) { console.warn("[backlight] falha ao parsear output:", e.message); }
		}
	}

	function adjust(delta) {
		const direction = delta >= 0 ? "+" : "-";
		const amount = Math.abs(delta) + "%";
		Quickshell.execDetached([
			Theme.binDir + "/backlight.sh", "set", amount + direction
		]);
		pollTimer.restart();
	}

	function set(percent) {
		const p = Math.round(Theme.clamp(percent, 0, 100));
		Quickshell.execDetached([
			Theme.binDir + "/backlight.sh", "set", p + "%"
		]);
		backlight.percent = p;
		pollTimer.restart();
	}
}