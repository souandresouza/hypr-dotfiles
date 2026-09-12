import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets
import "../Common/HeadphonesModel.js" as Model

// Earbuds/headsets battery on the bar. One mark per followed device, each
// filled with that device's battery; the tooltip reads every device at once.
// Click opens the popup.
ModuleButton {
	id: root

	property var popup: null
	property bool showPercentage: false
	property bool hideWhenDisconnected: true

	readonly property var service: HeadphonesService
	readonly property var followed: service.followed
	readonly property bool visibleMark:
		followed.length > 0 && (service.anyConnected || !hideWhenDisconnected)

	visible: visibleMark
	dim: !service.anyConnected
	urgent: service.primary && service.primary.low

	property string tooltipText: {
		if (followed.length === 0) return Model.tooltip({ hasDevice: false })
		var lines = []
		for (var i = 0; i < followed.length; i++)
			lines.push(Model.tooltip(followed[i].summary))
		return lines.join("\n")
	}

	Item {
		width: Math.max(16, Math.min(30, root.contentHeight * 0.6))
		height: root.contentHeight

		Row {
			id: markRow
			anchors.centerIn: parent
			spacing: 2

			Repeater {
				id: deviceRepeater
				model: root.visibleMark ? root.followed : []
				delegate: DeviceMark {
					required property var modelData
					follower: modelData
					markSize: {
						var n = root.followed.length > 0 ? root.followed.length : 1
						var avail = Math.min(30, root.contentHeight * 0.6)
						return Math.max(12, Math.min(avail / n, root.contentHeight * 0.55))
					}
				}
			}
		}
	}

	onClicked: {
		if (followed.length > 0)
			service.current = followed[0];
		if (popup)
			popup.toggleFrom(root.frame);
	}

	// ---- The mark: earbuds once a left and a right have reported, headphones
	//      for a single-battery headset and for a set that has not said yet.
	component DeviceMark: Item {
		id: mark
		required property var follower
		property real markSize: 16

		readonly property bool connected: follower ? follower.connected : false
		readonly property bool low: follower ? follower.low : false
		readonly property int level: follower ? follower.level : -1
		readonly property bool perBud: follower ? follower.perBud : false
		readonly property int singleLevel: follower ? follower.singleLevel : -1
		readonly property int rightLevel: follower ? follower.rightLevel : -1
		readonly property int leftLevel: follower ? follower.leftLevel : -1
		readonly property int bluezLevel: follower ? follower.bluezLevel : -1

		readonly property color tint: {
			if (low) return Theme.danger
			if (!connected) return Qt.rgba(Theme.sage.r, Theme.sage.g, Theme.sage.b, 0.55)
			return Theme.fg
		}

		readonly property bool earbuds: singleLevel < 0 && perBud
		readonly property int leftValue: singleLevel >= 0
			? singleLevel : (perBud ? leftLevel : bluezLevel)
		readonly property int rightValue: singleLevel >= 0
			? singleLevel : (perBud ? rightLevel : bluezLevel)

		readonly property real fillLeft: fraction(leftValue)
		readonly property real fillRight: fraction(rightValue)

		width: Math.max(12, markSize)
		height: markSize
		implicitWidth: width
		implicitHeight: height

		function fraction(v) {
			if (!isFinite(v) || v < 0) return 0
			return Math.max(0.04, Math.min(1, v / 100))
		}

		// The dim outline every state shares.
		HeadphonesGlyph {
			anchors.fill: parent
			earbuds: mark.earbuds
			tint: Qt.rgba(Theme.sage.r, Theme.sage.g, Theme.sage.b, 0.45)
		}

		// The bright fill, clipped to each side's level.
		Item {
			anchors.fill: parent
			clip: true
			visible: connected

			Item {
				id: leftWin
				clip: true
				width: parent.width / 2
				height: Math.max(1, Math.round(parent.height * fillLeft))
				anchors.bottom: parent.bottom
				visible: fillLeft > 0

				HeadphonesGlyph {
					width: parent.parent.width
					height: parent.parent.height
					x: -leftWin.x
					y: -leftWin.y
					earbuds: mark.earbuds
					tint: mark.tint
				}
			}

			Item {
				id: rightWin
				clip: true
				width: parent.width / 2
				height: Math.max(1, Math.round(parent.height * fillRight))
				anchors.bottom: parent.bottom
				visible: fillRight > 0

				HeadphonesGlyph {
					width: parent.parent.width
					height: parent.parent.height
					x: -rightWin.x
					y: -rightWin.y
					earbuds: mark.earbuds
					tint: mark.tint
				}
			}
		}
	}

	// A headset or a pair of earbuds, drawn from rectangles so that a fraction
	// of the item's height is exactly that fraction of the mark.
	component HeadphonesGlyph: Item {
		id: glyph
		property bool earbuds: false
		property color tint: Theme.fg

		readonly property real stroke: Math.max(1, Math.round(height * 0.09))
		readonly property real cupWidth: Math.max(3, Math.round(width * 0.30))
		readonly property real cupHeight: Math.max(3, Math.round(height * 0.42))

		// Headband is a clipped ring.
		Item {
			visible: !glyph.earbuds
			width: parent.width
			height: parent.height - glyph.cupHeight + glyph.stroke
			clip: true

			Rectangle {
				width: parent.width
				height: glyph.width
				radius: width / 2
				color: "transparent"
				border.width: glyph.stroke
				border.color: glyph.tint
			}
		}

		Rectangle {
			visible: !glyph.earbuds
			x: 0
			width: glyph.cupWidth
			height: glyph.cupHeight
			radius: Math.max(1, Math.round(glyph.cupWidth * 0.35))
			anchors.bottom: parent.bottom
			color: glyph.tint
		}

		Rectangle {
			visible: !glyph.earbuds
			x: glyph.width - glyph.cupWidth
			width: glyph.cupWidth
			height: glyph.cupHeight
			radius: Math.max(1, Math.round(glyph.cupWidth * 0.35))
			anchors.bottom: parent.bottom
			color: glyph.tint
		}

		// Earbuds: two capsules with inward stems.
		readonly property real bodyW: Math.max(3, Math.round(width * 0.36))
		readonly property real bodyH: Math.max(3, Math.round(height * 0.55))
		readonly property real stemW: Math.max(1, Math.round(width * 0.16))
		readonly property real inset: Math.round(width * 0.04)

		Rectangle {
			visible: glyph.earbuds
			x: glyph.inset; y: 0
			width: glyph.bodyW; height: glyph.bodyH
			radius: glyph.bodyW / 2
			color: glyph.tint
		}

		Rectangle {
			visible: glyph.earbuds
			x: glyph.inset + glyph.bodyW - glyph.stemW
			y: glyph.bodyH - glyph.stemW
			width: glyph.stemW; height: glyph.height - y
			radius: glyph.stemW / 2
			color: glyph.tint
		}

		Rectangle {
			visible: glyph.earbuds
			x: glyph.width - glyph.inset - glyph.bodyW; y: 0
			width: glyph.bodyW; height: glyph.bodyH
			radius: glyph.bodyW / 2
			color: glyph.tint
		}

		Rectangle {
			visible: glyph.earbuds
			x: glyph.width - glyph.inset - glyph.bodyW
			y: glyph.bodyH - glyph.stemW
			width: glyph.stemW; height: glyph.height - y
			radius: glyph.stemW / 2
			color: glyph.tint
		}
	}
}