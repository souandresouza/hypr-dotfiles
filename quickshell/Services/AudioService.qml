pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: audio

	property int volume: 0
	property bool muted: false

	Timer {
		id: pollTimer
		interval: 1000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: audio.refresh()
	}

	Process {
		id: volumeProcess

		running: false
		stdout: StdioCollector {
			id: coll
			waitForEnd: true
		}

		onExited: () => {
			const line = coll.text.toString().trim();
			const m = /Volume:\s*([0-9.]+)/.exec(line);
			if (m)
				audio.volume = Math.round(parseFloat(m[1]) * 100);
			audio.muted = /MUTED/.test(line);
		}
	}

	function refresh() {
		volumeProcess.exec(["/usr/bin/wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]);
	}

	function setVolume(v) {
		const p = Math.round(Theme.clamp(v, 0, 100));
		Quickshell.execDetached([
			"/usr/bin/wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", p + "%"
		]);
		audio.volume = p;
		pollTimer.restart();
	}

	function adjust(delta) {
		setVolume(audio.volume + delta);
	}

	function toggleMute() {
		Quickshell.execDetached(["/usr/bin/wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
		audio.muted = !audio.muted;
		pollTimer.restart();
	}
}