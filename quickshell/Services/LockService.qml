pragma Singleton
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Common

Singleton {
	id: lockservice

	property bool locked: false
	readonly property bool secure: typeof sessionLock !== "undefined" && sessionLock != null && sessionLock.secure
	property string password: ""
	property string feedback: ""
	property string pamState: ""
	property bool unlocking: false
	readonly property bool pamActive: pam != null && pam.active

	property bool fallbackActive: false

	readonly property string homeDir: Quickshell.env("HOME") || "/home/andre"
	readonly property string wallpaperUrl: "file://" + homeDir + "/.cache/current_wallpaper.png"
	readonly property string avatarUrl: "file://" + homeDir + "/Documentos/user.png"

	readonly property var weekdayNames: [
		"domingo", "segunda-feira", "terça-feira", "quarta-feira",
		"quinta-feira", "sexta-feira", "sábado"
	]
	readonly property var monthNames: [
		"janeiro", "fevereiro", "março", "abril", "maio", "junho",
		"julho", "agosto", "setembro", "outubro", "novembro", "dezembro"
	]

	function lock() {
		if (lockservice.locked || lockservice.fallbackActive)
			return;
		lockservice.password = "";
		lockservice.feedback = "";
		lockservice.pamState = "";
		lockservice.unlocking = false;
		pam.abort();
		lockservice.locked = true;
		watchdog.restart();
	}

	function unlock() {
		lockservice.locked = false;
		lockservice.unlocking = false;
		watchdog.stop();
	}

	function submit() {
		if (lockservice.fallbackActive)
			return;
		if (pam.active || lockservice.unlocking || lockservice.password.length === 0)
			return;
		lockservice.feedback = "";
		pam.start();
	}

	function spawnFallback() {
		if (lockservice.fallbackActive)
			return;
		lockservice.fallbackActive = true;
		lockservice.locked = false;
		watchdog.stop();
		pam.abort();
		fallbackProcess.running = true;
	}

	PamContext {
		id: pam

		config: "login"

		onResponseRequiredChanged: {
			if (pam.responseRequired)
				pam.respond(lockservice.password);
		}

		onCompleted: (result) => {
			if (result === PamResult.Success) {
				lockservice.unlocking = true;
				lockservice.unlock();
			} else if (result === PamResult.Failed) {
				lockservice.pamState = "fail";
				lockservice.feedback = "Senha incorreta";
				lockservice.password = "";
			} else if (result === PamResult.MaxTries) {
				lockservice.pamState = "max";
				lockservice.feedback = "Muitas tentativas";
				lockservice.password = "";
			} else {
				lockservice.pamState = "error";
				lockservice.feedback = "Erro de autenticação";
				lockservice.password = "";
			}
		}
	}

	Timer {
		id: watchdog

		interval: 2000
		repeat: false
		onTriggered: {
			if (!lockservice.secure)
				lockservice.spawnFallback();
		}
	}

	Process {
		id: fallbackProcess

		command: ["swaylock"]
		onExited: (code, status) => {
			lockservice.fallbackActive = false;
		}
	}

	Connections {
		target: sessionLock

		function onSecureStateChanged() {
			if (sessionLock.secure) {
				watchdog.stop();
				lockservice.password = "";
				lockservice.feedback = "";
				lockservice.pamState = "";
			} else if (lockservice.locked) {
				watchdog.start();
			}
		}
	}

	WlSessionLock {
		id: sessionLock

		locked: lockservice.locked

		WlSessionLockSurface {
			color: "#101011"

			FocusScope {
				id: surfaceContent
				anchors.fill: parent
				focus: sessionLock.secure

				opacity: sessionLock.secure ? 1 : 0
				enabled: opacity > 0

				Behavior on opacity {
					NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
				}

				SystemClock {
					id: systemClock
					precision: SystemClock.Seconds
					enabled: sessionLock.secure
				}

				property string dateStr: lockservice.weekdayNames[systemClock.date.getDay()]
					+ ", " + systemClock.date.getDate() + " de " + lockservice.monthNames[systemClock.date.getMonth()]
					+ " de " + systemClock.date.getFullYear()

				MouseArea {
					anchors.fill: parent
					onClicked: field.forceActiveFocus()
				}

				Rectangle {
					anchors.fill: parent
					color: "#101011"
				}

				Image {
					id: wallpaperImage
					anchors.fill: parent
					source: lockservice.wallpaperUrl
					fillMode: Image.PreserveAspectCrop
					smooth: true
					layer.enabled: true
					layer.effect: MultiEffect {
						blurEnabled: true
						blur: 0.8
						blurMax: 32
						blurMultiplier: 1
					}
				}

				Rectangle {
					anchors.fill: parent
					color: "black"
					opacity: 0.4
				}

				Column {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: 40
					spacing: 16

					Text {
						id: clockText
						anchors.horizontalCenter: parent.horizontalCenter
						text: Qt.formatTime(systemClock.date, "HH:mm:ss")
						font.family: Theme.fontFamily
						font.pixelSize: 120
						font.weight: Font.Light
						color: "white"
					}

					Text {
						id: dateText
						anchors.horizontalCenter: parent.horizontalCenter
						text: surfaceContent.dateStr
						font.family: Theme.fontFamily
						font.pixelSize: 26
						color: "white"
						opacity: 0.9
					}
				}

				Rectangle {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.top: surfaceContent.verticalCenter
					anchors.topMargin: 165
					width: 460
					height: 60
					radius: 16
					color: "#26262b"
					border.color: field.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.3)
					border.width: field.activeFocus ? 2 : 1

					Behavior on border.color {
						ColorAnimation { duration: 120 }
					}

					Text {
						id: lockIcon
						anchors.left: parent.left
						anchors.leftMargin: 16
						anchors.verticalCenter: parent.verticalCenter
						text: "\uf023"
						font.family: Theme.fontFamily
						font.pixelSize: 18
						color: field.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.5)
					}

					TextInput {
						id: field
						anchors.left: lockIcon.right
						anchors.leftMargin: 14
						anchors.right: enterButton.left
						anchors.rightMargin: 10
						anchors.verticalCenter: parent.verticalCenter
						focus: sessionLock.secure
						echoMode: TextInput.Password
						font.family: Theme.fontFamily
						font.pixelSize: 22
						color: "white"
						inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

						text: lockservice.password
						onTextChanged: lockservice.password = text
						onAccepted: lockservice.submit()

						Keys.onPressed: (event) => {
							if (event.key === Qt.Key_Escape) {
								lockservice.password = "";
								event.accepted = true;
							}
						}
					}

					Rectangle {
						id: enterButton
						anchors.right: parent.right
						anchors.rightMargin: 8
						anchors.verticalCenter: parent.verticalCenter
						width: 44
						height: 44
						radius: 22
						color: Theme.accent

						Text {
							anchors.centerIn: parent
							text: "\uf054"
							font.family: Theme.fontFamily
							font.pixelSize: 16
							color: "#101011"
						}

						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: lockservice.submit()
						}
					}

					Rectangle {
						id: avatarBox
						anchors.right: enterButton.left
						anchors.rightMargin: 12
						anchors.verticalCenter: parent.verticalCenter
						width: 36
						height: 36
						radius: 18
						color: "#101011"
						clip: true
						border.color: Qt.rgba(1, 1, 1, 0.2)
						border.width: 1

						Image {
							id: avatarImage
							anchors.fill: parent
							source: lockservice.avatarUrl
							fillMode: Image.PreserveAspectCrop
							mipmap: true
						}
					}
				}

				Text {
					id: feedbackText
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.top: parent.verticalCenter
					anchors.topMargin: 245
					visible: lockservice.feedback.length > 0
					text: lockservice.feedback
					font.family: Theme.fontFamily
					font.pixelSize: 14
					color: Theme.danger
				}
			}
		}
	}

	IpcHandler {
		target: "lock"

		function lock() {
			lockservice.lock();
		}

		function unlock() {
			lockservice.unlock();
		}

		function toggle() {
			if (lockservice.locked || lockservice.fallbackActive)
				lockservice.unlock();
			else
				lockservice.lock();
		}

		function isLocked() {
			return lockservice.locked || lockservice.fallbackActive;
		}

		function submit() {
			lockservice.submit();
		}
	}
}