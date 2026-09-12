import QtQuick
import QtQuick.Layouts
import qs.Common

Item {
	id: root

	property real minimum: 0
	property real maximum: 100
	property real value: 0
	property bool enabled: true
	property real sf: 1
	signal valuePushed(real v)
	signal interactionFinished

	readonly property real fraction: Theme.clamp(
		(value - minimum) / (maximum - minimum), 0, 1)

	height: Theme.roundScaled(18, root.sf)

	Rectangle {
		id: track
		width: parent.width
		height: Theme.roundScaled(6, root.sf)
		radius: Theme.roundScaled(3, root.sf)
		anchors.verticalCenter: parent.verticalCenter
		color: Theme.moduleHover
		visible: root.enabled
	}

	Rectangle {
		width: parent.width * root.fraction
		height: track.height
		radius: track.radius
		anchors.verticalCenter: parent.verticalCenter
		color: root.enabled ? Theme.accent : Theme.stone
		visible: root.enabled
	}

	Rectangle {
		width: Theme.roundScaled(12, root.sf)
		height: Theme.roundScaled(12, root.sf)
		radius: width / 2
		x: parent.width * root.fraction - width / 2
		anchors.verticalCenter: parent.verticalCenter
		color: Theme.fg
		border.color: Theme.moduleHover
		border.width: 1
		visible: root.enabled
	}

	MouseArea {
		anchors.fill: parent
		enabled: root.enabled
		acceptedButtons: Qt.LeftButton
		cursorShape: Qt.PointingHandCursor
		hoverEnabled: true

		function push(x) {
			const m = root.minimum
				+ (root.maximum - root.minimum) * Theme.clamp(x / parent.width, 0, 1);
			root.value = m;
			root.valuePushed(m);
		}

		onPressed: (mouse) => push(mouse.x)
		onPositionChanged: (mouse) => {
			if (mouse.pressed)
				push(mouse.x);
		}
		onReleased: root.interactionFinished()
		onWheel: (wheel) => {
			const d = wheel.angleDelta.y > 0 ? 5 : -5;
			const next = Theme.clamp(root.value + d, root.minimum, root.maximum);
			root.value = next;
			root.valuePushed(next);
		}
	}
}
