pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
	id: inhibitor

	property bool active: false

	PanelWindow {
		id: inhibitionWindow
		screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
		visible: inhibitor.active
		color: "transparent"

		WlrLayershell.namespace: "cadrocbar:idle-inhibitor"
		WlrLayershell.layer: WlrLayershell.Background
		WlrLayershell.exclusiveZone: -1
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

		anchors {
			top: true
			left: true
		}

		implicitWidth: 1
		implicitHeight: 1

		IdleInhibitor {
			id: inhibition
			window: inhibitionWindow
			enabled: inhibitor.active
		}
	}

	function enable() {
		inhibitor.active = true;
	}

	function disable() {
		inhibitor.active = false;
	}

	function toggle() {
		if (inhibitor.active)
			inhibitor.disable();
		else
			inhibitor.enable();
	}
}