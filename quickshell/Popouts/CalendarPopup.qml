import QtQuick
import qs.Common
import qs.Widgets

Item {
	id: root

	property real sf: 1

	readonly property real fitSf: Theme.roundScaled(Math.min(width, height), 1) / Theme.calendarDesign

	property int viewYear: new Date().getFullYear()
	property int viewMonth: new Date().getMonth()

	property var now: new Date()

	function msUntilNextDay() {
		const next = new Date();
		next.setHours(24, 0, 0, 0);
		return next.getTime() - Date.now() + 1000;
	}

	Timer {
		id: midnightTimer
		interval: root.msUntilNextDay()
		running: true
		onTriggered: {
			root.now = new Date();
			root.viewYear = root.now.getFullYear();
			root.viewMonth = root.now.getMonth();
			midnightTimer.interval = root.msUntilNextDay();
		}
	}
	readonly property var monthNames: ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
	readonly property var weekdayNames: ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"]

	readonly property int firstDow: new Date(viewYear, viewMonth, 1).getDay()
	readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()
	readonly property int daysPrevMonth: new Date(viewYear, viewMonth, 0).getDate()

	Column {
		anchors.fill: parent
		anchors.margins: Theme.roundScaled(16, root.fitSf)
		spacing: Theme.roundScaled(12, root.fitSf)

		Row {
			width: parent.width
			height: Theme.roundScaled(28, root.fitSf)
			spacing: Theme.roundScaled(8, root.fitSf)

			ModuleButton {
				width: Theme.roundScaled(28, root.fitSf)
					height: Theme.roundScaled(28, root.fitSf)
					padding: Theme.roundScaled(6, root.fitSf)
				IconText { glyph: "\uf053" }
				onClicked: {
					root.viewMonth--;
					if (root.viewMonth < 0) {
						root.viewMonth = 11;
						root.viewYear--;
					}
				}
			}

			Text {
				width: parent.width - Theme.roundScaled(28, root.fitSf) * 2 - Theme.roundScaled(8, root.fitSf) * 2
				height: Theme.roundScaled(28, root.fitSf)
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				elide: Text.ElideRight
				text: root.monthNames[root.viewMonth].toUpperCase() + " " + root.viewYear
				font.family: Theme.fontFamily
				font.pixelSize: Theme.roundScaled(Theme.fontSizeLarge, root.fitSf)
				font.weight: Font.Bold
				color: Theme.fg
			}

			ModuleButton {
				width: Theme.roundScaled(28, root.fitSf)
					height: Theme.roundScaled(28, root.fitSf)
					padding: Theme.roundScaled(6, root.fitSf)
				IconText { glyph: "\uf054" }
				onClicked: {
					root.viewMonth++;
					if (root.viewMonth > 11) {
						root.viewMonth = 0;
						root.viewYear++;
					}
				}
			}
		}

		Row {
			width: parent.width
			spacing: Theme.roundScaled(2, root.fitSf)

			Repeater {
				model: root.weekdayNames
				delegate: Item {
					required property string modelData
					width: (parent.width - Theme.roundScaled(12, root.fitSf)) / 7
					height: Theme.roundScaled(20, root.fitSf)
					Text {
						anchors.centerIn: parent
						text: modelData
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, root.fitSf)
						color: Theme.sage
					}
				}
			}
		}

		Grid {
			id: grid
			columns: 7
			width: parent.width
			spacing: Theme.roundScaled(2, root.fitSf)

			Repeater {
				model: 42

				delegate: Item {
					required property int index
					width: (grid.width - Theme.roundScaled(12, root.fitSf)) / 7
					height: Theme.roundScaled(34, root.fitSf)

					readonly property int cellDay: index - root.firstDow + 1
					readonly property bool inMonth: cellDay >= 1 && cellDay <= root.daysInMonth
					readonly property bool isToday: inMonth
						&& cellDay === root.now.getDate()
						&& root.viewMonth === root.now.getMonth()
						&& root.viewYear === root.now.getFullYear()
					readonly property int dayNumber: inMonth
						? cellDay
						: cellDay < 1 ? root.daysPrevMonth + cellDay : cellDay - root.daysInMonth

					Rectangle {
						id: dayRect
						anchors.fill: parent
						anchors.margins: 1
						radius: Theme.moduleRadius
						color: {
							if (isToday)
								return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22);
							return "transparent";
						}
						border.width: isToday ? Theme.roundScaled(2, root.fitSf) : 0
						border.color: Theme.accent
					}

					Text {
						anchors.centerIn: parent
						text: String(dayNumber)
						font.family: Theme.fontFamily
						font.pixelSize: Theme.roundScaled(Theme.fontSize, root.fitSf)
						color: {
							if (isToday)
								return Theme.accent;
							if (!inMonth)
								return Qt.rgba(Theme.stone.r, Theme.stone.g, Theme.stone.b, 0.45);
							return Theme.fg;
						}
					}
				}
			}
		}
	}
}