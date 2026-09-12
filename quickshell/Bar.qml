import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules
import qs.Popouts

Item {
	id: barRoot

	required property var screen

	Timer {
		interval: 300
		repeat: false
		running: true
		onTriggered: walProcess.exec([Theme.binDir + "/launcher.py"])
	}

	Process {
		id: walProcess

		running: false
		stdout: StdioCollector {
			id: walColl
			waitForEnd: true
		}

		onExited: () => {
			const line = walColl.text.toString().trim();
			if (line.length === 0) return;
			try {
				const j = JSON.parse(line);
				if (j && j.wal && j.wal.background)
					Theme.walColors = j.wal;
			} catch (e) { console.error("[cadrocbar] falha ao parsear cores wal:", e.message); }
		}
	}

	PanelWindow {
		id: barWindow
		screen: barRoot.screen
		visible: true
		color: "transparent"

		WlrLayershell.namespace: "cadrocbar"
		WlrLayershell.layer: WlrLayershell.Top
		WlrLayershell.exclusiveZone: Theme.barHeight + Theme.barTopMargin
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

		anchors {
			top: true
			left: true
			right: true
		}

		implicitHeight: Theme.barHeight

		Item {
			id: layout
			anchors.fill: parent
			anchors.topMargin: Theme.barTopMargin

			Row {
				id: leftSection
				spacing: Theme.moduleSpacing
				anchors.left: parent.left
				anchors.leftMargin: 8
				anchors.verticalCenter: parent.verticalCenter

				Launcher { screen: barRoot.screen }
				Workspaces { screen: barRoot.screen }
				FocusedWindow { screen: barRoot.screen }
				Media { popup: mediaPopup }
			}

			Item {
				id: centerSection
				anchors.left: leftSection.right
				anchors.leftMargin: Theme.moduleSpacing
				anchors.right: rightSection.left
				anchors.rightMargin: Theme.moduleSpacing
				anchors.top: parent.top
				anchors.bottom: parent.bottom

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.verticalCenter: parent.verticalCenter
					spacing: Theme.moduleSpacing

					Clock { popup: calendarPopup }
				}
			}

			Row {
				id: rightSection
				spacing: Theme.moduleSpacing
				anchors.right: parent.right
				anchors.rightMargin: 8
				anchors.verticalCenter: parent.verticalCenter

					PowerMenu { popup: powerMenuPopup }
					Lock {}
					IdleInhibitor {}
					Network { popup: networkPopup }
					ControlCenter { popup: controlCenterPopup }
					Notifications { popup: notificationsPopup }
					PowerProfile {}
					Battery {}
			}
		}
	}

	PopoutBase {
		id: calendarPopup
		screen: barRoot.screen
		popupSizeFraction: 0.15
		content: Component {
			CalendarPopup {}
		}
	}

	PopoutBase {
		id: mediaPopup
		screen: barRoot.screen
		popupHeight: 300
		sizeToTrigger: true
		content: Component {
			MediaPopup {}
		}
	}

	PopoutBase {
		id: controlCenterPopup
		screen: barRoot.screen
		popupHeight: 460
		content: Component {
			ControlCenterPopup {}
		}
	}

	PopoutBase {
		id: networkPopup
		screen: barRoot.screen
		popupWidth: 360
		popupHeight: 640
		content: Component {
			NetworkPopup {}
		}
	}

	PopoutBase {
		id: notificationsPopup
		screen: barRoot.screen
		popupWidth: 380
		popupHeight: 420
		content: Component {
			NotificationsPopup {}
		}
	}

	PopoutBase {
		id: powerMenuPopup
		screen: barRoot.screen
		popupWidth: 220
		popupHeight: 240
		content: Component {
			PowerMenuPopup {}
		}
	}

	function closeOtherPopouts(except) {
		const all = [calendarPopup, mediaPopup, controlCenterPopup, networkPopup, powerMenuPopup, notificationsPopup];
		for (const p of all) {
			if (p !== except)
				p.closePopup();
		}
	}

	Component.onCompleted: {
		PopupService.controlCenter = controlCenterPopup;
		PopupService.media = mediaPopup;
		PopupService.calendar = calendarPopup;
		PopupService.powerMenu = powerMenuPopup;
		PopupService.network = networkPopup;
	}

	Connections {
		target: calendarPopup
		function onOpened() { barRoot.closeOtherPopouts(calendarPopup) }
	}

	Connections {
		target: mediaPopup
		function onOpened() { barRoot.closeOtherPopouts(mediaPopup) }
	}

	Connections {
		target: controlCenterPopup
		function onOpened() { barRoot.closeOtherPopouts(controlCenterPopup) }
	}

	Connections {
		target: networkPopup
		function onOpened() { barRoot.closeOtherPopouts(networkPopup) }
	}

	Connections {
		target: powerMenuPopup
		function onOpened() { barRoot.closeOtherPopouts(powerMenuPopup) }
	}

	Connections {
		target: notificationsPopup
		function onOpened() { barRoot.closeOtherPopouts(notificationsPopup) }
	}

	Connections {
		target: powerMenuPopup.contentItem
		function onActionTriggered() { powerMenuPopup.closePopup() }
	}
}