pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: popups

	property Item controlCenter: null
	property Item media: null
	property Item calendar: null
	property Item powerMenu: null

	function toggleControl() {
		const p = popups.controlCenter;
		if (!p)
			return;
		if (p.open) {
			p.closePopup();
			return;
		}
		p.triggerX = Math.max(0, Math.floor((p.screenWidth - p.popupWidthScaled) / 2));
		p.triggerY = p.maskY;
		p.triggerWidth = p.popupWidthScaled;
		p.triggerHeight = 0;
		p.open = true;
		p.opened();
	}

	IpcHandler {
		target: "control"

		function toggle() {
			popups.toggleControl();
		}
	}
}