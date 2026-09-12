import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

Item {
	id: root

	required property var screen

	property int popupWidth: Theme.popupWidth
	property int popupHeight: 360
	property real popupSizeFraction: 0
	property Component content: null
	property string layerNamespace: "cadrocbar:popout"
	property bool sizeToTrigger: false

	property Item contentItem: null

	property bool open: false
	signal opened
	signal closed

	property int triggerX: 0
	property int triggerY: 0
	property int triggerWidth: 0
	property int triggerHeight: 0

	readonly property int screenWidth: screen ? screen.width : 0
	readonly property int screenHeight: screen ? screen.height : 0

	readonly property real sf: Math.max(0.75, Math.round((screenHeight / Theme.referenceHeight) * 100) / 100)

	readonly property int popupWidthScaled: sizeToTrigger
		? Theme.clamp(triggerWidth, Theme.popupMinWidth, Math.max(Theme.popupMinWidth, screenWidth - Theme.popupGap * 2))
		: popupSizeFraction > 0
			? Math.max(Theme.popupGap * 2, Math.round(screenWidth * popupSizeFraction))
			: Theme.roundScaled(popupWidth, sf)
	readonly property int popupHeightScaled: popupSizeFraction > 0
		? Math.max(Theme.popupGap * 2, Math.round(screenWidth * popupSizeFraction))
		: Theme.roundScaled(popupHeight, sf)

	readonly property int alignedX: Theme.clamp(
		triggerX + Math.floor(triggerWidth / 2) - Math.floor(popupWidthScaled / 2),
		Theme.popupGap, Math.max(Theme.popupGap, screenWidth - popupWidthScaled - Theme.popupGap))

	readonly property int alignedY: Theme.clamp(
		triggerY + triggerHeight + Theme.popupGap,
		Theme.popupGap, Math.max(Theme.popupGap, screenHeight - popupHeightScaled - Theme.popupGap))

	readonly property int maskY: Theme.barHeight + Theme.barTopMargin

	function screenPos(item) {
		if (!item)
			return { "x": 0, "y": 0 };
		const pos = item.mapToItem(null, 0, 0);
		return {
			"x": Math.round(pos.x),
			"y": Math.round(pos.y),
			"width": Math.round(item.width),
			"height": Math.round(item.height)
		};
	}

	function openFrom(item) {
		if (open) {
			closePopup();
			return;
		}
		const pos = screenPos(item);
		triggerX = pos.x;
		triggerY = pos.y;
		triggerWidth = pos.width;
		triggerHeight = pos.height;
		root.open = true;
		opened();
	}

	function toggleFrom(item) {
		open ? closePopup() : openFrom(item);
	}

	function closePopup() {
		if (!open)
			return;
		root.open = false;
		closed();
	}

	PanelWindow {
		id: popupWindow
		screen: root.screen
		visible: root.open
		color: "transparent"

		WlrLayershell.namespace: root.layerNamespace
		WlrLayershell.layer: WlrLayershell.Top
		WlrLayershell.exclusiveZone: -1
		WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

		anchors {
			left: true
			right: true
			top: true
			bottom: true
		}

		mask: Region {
			item: Rectangle {
				x: 0
				y: root.maskY
				width: root.screenWidth
				height: Math.max(0, root.screenHeight - root.maskY)
			}
		}

		MouseArea {
			id: dismissArea
			x: 0
			y: root.maskY
			width: root.screenWidth
			height: Math.max(0, root.screenHeight - root.maskY)
			enabled: root.open
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

			onClicked: (mouse) => root.closePopup()
		}

		Item {
			id: surface
			x: root.alignedX
			y: root.alignedY
			width: root.popupWidthScaled
			height: root.popupHeightScaled

			Loader {
				id: contentLoader
				anchors.fill: parent
				sourceComponent: root.content

				onLoaded: {
					root.contentItem = item;
					if (item && typeof item.sf === "number")
						item.sf = root.sf;
				}
			}

			Rectangle {
				anchors.fill: parent
				z: -1
				radius: Theme.popupRadius
				color: Qt.rgba(Theme.popupBg.r, Theme.popupBg.g, Theme.popupBg.b, 0.95)
				border.width: 1
				border.color: Theme.popupBorder

				Rectangle {
					anchors.fill: parent
					radius: Theme.popupRadius
					color: "transparent"
					border.width: 2
					border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
				}
			}

			Item {
				id: focusHelper
				anchors.fill: parent
				focus: root.open

				Keys.onPressed: (event) => {
					if (event.key === Qt.Key_Escape) {
						root.closePopup();
						event.accepted = true;
					}
				}
			}
		}
	}
}