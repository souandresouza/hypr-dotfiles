import QtQuick
import QtQuick.Layouts
import qs.Common

Item {
	id: root

	property bool active: false
	property bool urgent: false
	property bool dim: false
	property bool framed: true
	property bool contentCentered: false

	property color baseColor: Theme.fg
	property color accentColor: Theme.accent

	signal clicked
	signal rightClicked
	signal middleClicked
	signal wheelUp
	signal wheelDown

	readonly property bool hovered: mouseArea.containsMouse
	property alias frame: frame
	property int padding: Theme.modulePadding

	implicitWidth: contentRow.width + (framed ? padding * 2 : padding)
	implicitHeight: Theme.contentHeight

	readonly property color frameColor: {
		if (active)
			return accentColor;
		if (urgent)
			return Theme.danger;
		if (dim)
			return Qt.rgba(Theme.sage.r, Theme.sage.g, Theme.sage.b, 0.45);
		return baseColor;
	}

	readonly property color fillColor: {
		if (active)
			return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18);
		if (urgent)
			return Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15);
		if (hovered && framed)
			return Theme.moduleHover;
		return framed ? Theme.moduleFill : "transparent";
	}

	RowLayout {
		id: contentRow
		anchors.left: parent.left
		anchors.leftMargin: framed ? root.padding : root.padding / 2
		anchors.horizontalCenter: root.contentCentered ? parent.horizontalCenter : undefined
		anchors.verticalCenter: parent.verticalCenter
		spacing: 6
	}

	Rectangle {
		id: frame
		anchors.fill: parent
		radius: Theme.moduleRadius
		color: root.fillColor
		border.width: framed ? Theme.borderWidth : 0
		border.color: root.frameColor
		z: -1

		Behavior on color {
			ColorAnimation { duration: 120 }
		}
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		cursorShape: Qt.PointingHandCursor

		onPressed: (mouse) => {
			if (mouse.button === Qt.RightButton)
				root.rightClicked();
			else if (mouse.button === Qt.MiddleButton)
				root.middleClicked();
		}
		onClicked: (mouse) => {
			if (mouse.button === Qt.LeftButton)
				root.clicked();
		}
		onWheel: (wheel) => {
			if (wheel.angleDelta.y > 0)
				root.wheelUp();
			else
				root.wheelDown();
		}
	}

	default property alias content: contentRow.data
}