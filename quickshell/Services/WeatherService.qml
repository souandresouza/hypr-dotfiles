pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: weather

	property string cond: ""
	property string glyph: ""
	property string temp: ""
	property string wind: ""
	property string hum: ""
	readonly property bool available: weather.temp.length > 0

	Timer {
		interval: 1800000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: weatherProcess.exec([Theme.binDir + "/weather.sh"])
	}

	Process {
		id: weatherProcess

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
				weather.cond = String(j.cond || "");
				weather.glyph = String(j.glyph || "");
				weather.temp = String(j.temp || "");
				weather.wind = String(j.wind || "");
				weather.hum = String(j.hum || "");
			} catch (e) { console.warn("[weather] falha ao parsear output:", e.message); }
		}
	}
}