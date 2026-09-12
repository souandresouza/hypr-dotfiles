import QtQuick
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	readonly property bool available: typeof PowerProfiles !== "undefined"
	readonly property int profile: available ? PowerProfiles.profile : -1

	readonly property string label: {
		if (profile === PowerProfile.PowerSaver)
			return "eco";
		if (profile === PowerProfile.Balanced)
			return "bal";
		if (profile === PowerProfile.Performance)
			return "per";
		return "";
	}

	readonly property color labelColor: profile === PowerProfile.PowerSaver ? Theme.sage
		: profile === PowerProfile.Performance ? Theme.accent : Theme.fg

	visible: available

	IconText {
		text: root.label
		textColor: root.labelColor
		fontWeight: Font.Medium
	}

	onClicked: {
		if (!root.available)
			return;
		if (profile === PowerProfile.PowerSaver)
			PowerProfiles.profile = PowerProfile.Balanced;
		else if (profile === PowerProfile.Balanced)
			PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
		else
			PowerProfiles.profile = PowerProfile.PowerSaver;
	}
}