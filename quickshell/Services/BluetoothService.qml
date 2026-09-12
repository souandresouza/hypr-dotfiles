pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: bluetooth

	property bool powered: false
	property int connected: 0

	Timer {
		interval: 4000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: btProcess.exec([Theme.binDir + "/bluetooth.sh"])
	}

	Process {
		id: btProcess

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
				bluetooth.powered = j.powered === "yes";
				bluetooth.connected = Number(j.connected) || 0;
			} catch (e) { console.warn("[bluetooth] falha ao parsear output:", e.message); }
		}
	}

	function togglePower() {
		Quickshell.execDetached(["bluetoothctl", "power", powered ? "off" : "on"]);
	}
}