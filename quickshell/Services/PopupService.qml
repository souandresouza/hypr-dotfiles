pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: popups

	property Item media: null
	property Item calendar: null
	property Item powerMenu: null
	property Item clipboard: null
}