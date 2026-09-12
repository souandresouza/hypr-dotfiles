pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: stats

	property int cpu: 0
	property int memPct: 0
	property int memUsedMb: 0
	property int memTotalMb: 0
	property int temp: 0
	property int gpu: 0

	Timer {
		interval: 2000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: statsProcess.exec([Theme.binDir + "/sysinfo.sh"])
	}

	Process {
		id: statsProcess

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
				stats.cpu = Number(j.cpu) || 0;
				stats.memPct = Number(j.mem_pct) || 0;
				stats.memUsedMb = Number(j.mem_used_mb) || 0;
				stats.memTotalMb = Number(j.mem_total_mb) || 0;
				stats.temp = Number(j.temp) || 0;
				stats.gpu = Number(j.gpu) || 0;
			} catch (e) { console.warn("[sysinfo] falha ao parsear output:", e.message); }
		}
	}
}