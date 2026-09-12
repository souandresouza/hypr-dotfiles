pragma Singleton
import QtQuick
import Quickshell

Singleton {
	id: root

	property var walColors: ({})

	function hexColor(hex, a) {
		const m = /^#?([0-9a-f]{6})/i.exec(hex || "");
		if (!m)
			return a !== undefined ? Qt.rgba(0, 0, 0, a) : "#000000";
		const r = parseInt(m[1].substr(0, 2), 16) / 255;
		const g = parseInt(m[1].substr(2, 2), 16) / 255;
		const b = parseInt(m[1].substr(4, 2), 16) / 255;
		return a !== undefined ? Qt.rgba(r, g, b, a) : Qt.rgba(r, g, b, 1);
	}

	function darken(hex, f) {
		const m = /^#?([0-9a-f]{6})/i.exec(hex || "");
		if (!m) return "#000000";
		const r = parseInt(m[1].substr(0, 2), 16);
		const g = parseInt(m[1].substr(2, 2), 16);
		const b = parseInt(m[1].substr(4, 2), 16);
		return Qt.rgba(r * f / 255, g * f / 255, b * f / 255, 1);
	}

	// ---- palette (com fallbacks do wal) ----
	readonly property color bg: root.walColors.background
		? root.hexColor(root.walColors.background)
		: "#101011"
	readonly property color fg: root.walColors.foreground
		? root.hexColor(root.walColors.foreground)
		: "#e7dac6"
	readonly property color accent: root.walColors.color2
		? root.hexColor(root.walColors.color2)
		: "#ECC17E"
	readonly property color accentSoft: root.walColors.color4
		? root.hexColor(root.walColors.color4)
		: "#D09C67"
	readonly property color olive: root.walColors.color1
		? root.hexColor(root.walColors.color1)
		: "#B28C5E"
	readonly property color sage: root.walColors.color6
		? root.hexColor(root.walColors.color6)
		: "#7B837D"
	readonly property color bone: root.walColors.color7
		? root.hexColor(root.walColors.color7)
		: "#C6BDA7"
	readonly property color stone: root.walColors.color8
		? root.hexColor(root.walColors.color8)
		: "#a1988a"
	readonly property color danger: "#cc6666"

	readonly property color popupBg: root.walColors.background
		? root.hexColor(root.walColors.background, 0.97)
		: "#1a1a1e99"
	readonly property color popupBorder: root.walColors.color4
		? root.hexColor(root.walColors.color4, 0.6)
		: "#2b2b31"
	readonly property color moduleFill: root.walColors.background
		? root.hexColor(root.walColors.background, 0.55)
		: "#18181c"
	readonly property color moduleHover: root.walColors.background
		? root.darken(root.walColors.background, 0.94)
		: "#222226"
	readonly property color barFill: "#00000000"

	// ---- medidas ----
	readonly property int barHeight: 36
	readonly property int barTopMargin: 4
	readonly property int contentHeight: barHeight - barTopMargin
	readonly property int modulePadding: 10
	readonly property int moduleSpacing: 6
	readonly property int moduleRadius: 2
	readonly property int borderWidth: 2
	readonly property int popupRadius: 4
	readonly property int popupGap: 6
	readonly property int popupWidth: 360
	readonly property int popupMinWidth: 300
	readonly property int calendarDesign: 360

	readonly property int referenceHeight: 737

	function roundScaled(v, sf) {
		return Math.max(1, Math.round(v * sf));
	}

	readonly property string fontFamily: "JetBrainsMono Nerd Font"
	readonly property int fontSize: 12
	readonly property int fontSizeSmall: 10
	readonly property int fontSizeLarge: 15
	readonly property int iconSize: 14

	readonly property string binDir: Quickshell.shellDir + "/../scripts"

	function clamp(v, min, max) {
		return Math.max(min, Math.min(max, v));
	}
}