pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: mpris

	property var players: []

	readonly property var player: {
		for (let i = 0; i < players.length; i++) {
			if (players[i].status === "Playing")
				return players[i];
		}
		return players.length ? players[0] : null;
	}

	readonly property bool playing: player !== null && player.status === "Playing"
	readonly property string title: player ? (player.title || "") : ""
	readonly property string artist: player ? (player.artist || "") : ""

	Timer {
		id: pollTimer
		interval: 1000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: mprisProcess.exec([Theme.binDir + "/mpris.py"])
	}

	Process {
		id: mprisProcess

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
				if (Array.isArray(j))
					mpris.players = j;
			} catch (e) {
				console.warn("[mpris] falha ao parsear output:", e.message);
			}
		}
	}

	function send(id, cmd, value) {
		const args = [Theme.binDir + "/mpris.py", "--action", id, cmd];
		if (value !== undefined)
			args.push(value);
		Quickshell.execDetached(args);
	}

	function togglePlayback(player) {
		if (!player)
			return;
		if (player.canControl)
			send(player.id, "play-pause");
		else if (player.status === "Playing")
			send(player.id, "pause");
		else
			send(player.id, "play");
	}

	function volumeSet(player, v) {
		if (player)
			send(player.id, "volume", String(Theme.clamp(v, 0, 1)));
	}
}