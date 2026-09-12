import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	readonly property var dev: UPower.displayDevice
	readonly property bool present: dev && dev.isPresent
	readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
	readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false

	readonly property string glyph: {
		if (!present)
			return "";
		if (charging)
			return "\uf0e7";
		if (pct >= 90)
			return "\uf240";
		if (pct >= 70)
			return "\uf241";
		if (pct >= 50)
			return "\uf242";
		if (pct >= 30)
			return "\uf243";
		return "\uf244";
	}

	readonly property color glyphColor: present ? (pct <= 20 && !charging ? Theme.danger : charging ? Theme.accent : Theme.fg) : Theme.sage

	visible: present

	IconText {
		glyph: root.glyph
		text: root.pct + "%"
		glyphColor: root.glyphColor
		textColor: root.pct <= 20 && !root.charging ? Theme.danger : Theme.fg
	}
}