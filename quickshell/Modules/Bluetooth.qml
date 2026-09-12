import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	IconText {
		glyph: "\uf294"
		text: BluetoothService.powered ? String(BluetoothService.connected || 0) : ""
		glyphColor: BluetoothService.powered ? Theme.accent : Theme.sage
		textColor: BluetoothService.powered ? Theme.fg : Theme.sage
	}

	onClicked: BluetoothService.togglePower()
}