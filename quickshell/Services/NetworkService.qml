pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: network

	property int state: 0
	property string ssid: ""
	property int signal: 0
	property bool wifiEnabled: false
	property var networks: []
	property bool connectBusy: false
	property string connectFeedback: ""

	Timer {
		id: pollTimer
		interval: 5000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: networkProcess.exec([Theme.binDir + "/network.sh"])
	}

	Timer {
		id: networksTimer
		interval: 15000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: network.refreshNetworks()
	}

	Process {
		id: networkProcess

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
				network.state = j.state === "wifi" ? 1 : j.state === "ethernet" ? 2 : 0;
				network.ssid = j.ssid || "";
				network.signal = Number(j.signal) || 0;
				network.wifiEnabled = j.wifi_enabled === "yes";
			} catch (e) { console.warn("[rede] falha ao parsear output:", e.message); }
		}
	}

	Process {
		id: wifiListProcess

		running: false
		stdout: StdioCollector {
			id: wifiColl
			waitForEnd: true
		}

		onExited: (exitCode) => {
			if (exitCode !== 0)
				return;
			const line = wifiColl.text.toString().trim();
			if (line.length === 0)
				return;
			try {
				const arr = JSON.parse(line);
				if (Array.isArray(arr))
					network.networks = arr;
			} catch (e) { console.warn("[rede] falha ao parsear redes:", e.message); }
		}
	}

	Process {
		id: connectProcess

		running: false
		stdout: StdioCollector {
			id: connectColl
			waitForEnd: true
		}

		onExited: (exitCode) => {
			network.connectBusy = false;
			const out = connectColl.text.toString().trim();
			network.connectFeedback = exitCode === 0
				? (out || "Conectado")
				: (out || "Falha ao conectar");
			pollTimer.restart();
			network.refreshNetworks();
		}
	}

	function refreshNetworks() {
		if (!network.wifiEnabled) {
			network.networks = [];
			return;
		}
		wifiListProcess.exec([Theme.binDir + "/wifi-networks.py"]);
	}

	function connectTo(ssid, password) {
		network.connectBusy = true;
		network.connectFeedback = "";
		const args = ["nmcli", "dev", "wifi", "connect", ssid];
		if (password && password.length > 0)
			args.push("password", password);
		connectProcess.exec(args);
	}

	function toggleWifi() {
		Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
		pollTimer.restart();
		network.refreshNetworks();
	}
}