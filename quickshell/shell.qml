//@ pragma Env QSG_RENDER_LOOP=threaded
import QtQuick
import Quickshell

ShellRoot {
	Component.onCompleted: {
		Quickshell.watchFiles = true;
	}

	Variants {
		model: Quickshell.screens

		delegate: Loader {
			required property var modelData
			sourceComponent: Bar { screen: modelData }
		}
	}
}