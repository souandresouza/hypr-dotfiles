import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

Item {
	id: workspaces

	required property var screen

	readonly property var monitor: Hyprland.monitorFor(screen)

	height: Theme.contentHeight
	implicitWidth: row.implicitWidth

	Row {
		id: row
		spacing: 4
		anchors.verticalCenter: parent.verticalCenter

		Repeater {
			id: model
			model: Hyprland.workspaces

			delegate: ModuleButton {
				required property var modelData
				readonly property var ws: modelData

				width: 26
				height: Theme.contentHeight
				visible: ws && ws.monitor === workspaces.monitor
					&& (ws.toplevels.values.length > 0
						|| (workspaces.monitor && workspaces.monitor.activeWorkspace
							&& ws.id === workspaces.monitor.activeWorkspace.id))
				active: ws && workspaces.monitor && workspaces.monitor.activeWorkspace
					&& ws.id === workspaces.monitor.activeWorkspace.id
				urgent: ws && ws.urgent
				dim: ws && ws.toplevels.values.length === 0
				accentColor: Theme.accent

				IconText {
					text: parent.ws ? String(parent.ws.id) : ""
					textColor: parent.active ? Theme.accent
						: parent.urgent ? Theme.danger
						: Theme.fg
				}

				onClicked: parent.ws && parent.ws.activate()
			}
		}
	}
}