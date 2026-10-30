/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects 1.0

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.breeze.components

SessionManagementScreen {
    id: sessionManager

    readonly property alias mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false
    property alias showPassword: passwordBox.showPassword

    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal passwordResult(string password)

    onUserSelected: {
        const nextControl = (passwordBox.visible ? passwordBox : loginButton);
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function startLogin() {
        const password = passwordBox.text
        loginButton.forceActiveFocus();
        passwordResult(password);
    }

    Item {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(360, sessionManager.width * 0.9)
        Layout.maximumWidth: 360

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Kirigami.Units.largeSpacing
                text: sessionManager.userList.selectedUser ? sessionManager.userList.selectedUser : ""
                color: "#FFFFFF"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
                font.weight: Font.Normal
            }

            Item {
                id: passwordFieldContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.bottomMargin: Kirigami.Units.largeSpacing

                PlasmaExtras.PasswordField {
                    id: passwordBox
                    anchors.fill: parent
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    text: PasswordSync.password
                    placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder in text field", "Password")
                    focus: true
                    enabled: !authenticator.graceLocked
                    cursorVisible: visible
                    leftPadding: 16
                    rightPadding: loginButton.width + 12

                    background: Rectangle {
                        radius: 6
                        border.width: 1
                        border.color: passwordBox.activeFocus ? "#2563EB" : "#3F3F3F"
                        color: "#1A1A1A"
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }

                    onAccepted: {
                        if (sessionManager.lockScreenUiVisible) {
                            sessionManager.startLogin();
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Left && !text) {
                            sessionManager.userList.decrementCurrentIndex();
                            event.accepted = true
                        }
                        if (event.key === Qt.Key_Right && !text) {
                            sessionManager.userList.incrementCurrentIndex();
                            event.accepted = true
                        }
                    }

                    Keys.onReleased: {
                        if (loginButton.opacity == 0 && length > 0) {
                            showLoginButton.start()
                        }
                        if (loginButton.opacity > 0 && length == 0) {
                            hideLoginButton.start()
                        }
                    }

                    Connections {
                        target: root
                        function onClearPassword() {
                            passwordBox.forceActiveFocus()
                            passwordBox.text = "";
                            passwordBox.text = Qt.binding(() => PasswordSync.password);
                        }
                        function onNotificationRepeated() {
                            sessionManager.playHighlightAnimation();
                        }
                    }
                }

                Binding {
                    target: PasswordSync
                    property: "password"
                    value: passwordBox.text
                }

                Item {
                    id: loginButton
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    opacity: passwordBox.text.length > 0 ? 1.0 : 0
                    visible: opacity > 0

                    Rectangle {
                        id: buttonBg
                        anchors.fill: parent
                        radius: 4
                        color: "#2563EB"
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }

                    Image {
                        anchors.centerIn: parent
                        source: "image://icon/go-next-symbolic"
                        sourceSize: Qt.size(16, 16)
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { buttonBg.color = "#1D4ED8" }
                        onExited: { buttonBg.color = "#2563EB" }
                        onPressed: { buttonBg.color = "#1E40AF" }
                        onReleased: { buttonBg.color = "#2563EB"; sessionManager.startLogin(); }
                    }

                    PropertyAnimation {
                        id: showLoginButton
                        target: loginButton
                        properties: "opacity"
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        id: hideLoginButton
                        target: loginButton
                        properties: "opacity"
                        to: 0
                        duration: 100
                        easing.type: Easing.InCubic
                    }
                }
            }

            component FailableLabel : PlasmaComponents3.Label {
                id: _failableLabel
                required property int kind
                required property string label
                visible: authenticator.authenticatorTypes & kind
                text: label
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                RejectPasswordAnimation {
                    id: _rejectAnimation
                    target: _failableLabel
                    onFinished: _timer.restart()
                }
                Connections {
                    target: authenticator
                    function onNoninteractiveError(kind, authenticator) {
                        if (kind & _failableLabel.kind) {
                            _failableLabel.text = Qt.binding(() => authenticator.errorMessage)
                            _rejectAnimation.start()
                        }
                    }
                }
                Timer {
                    id: _timer
                    interval: Kirigami.Units.humanMoment
                    onTriggered: {
                        _failableLabel.text = Qt.binding(() => _failableLabel.label)
                    }
                }
            }

            FailableLabel {
                kind: ScreenLocker.Authenticator.Fingerprint
                label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
            }
            FailableLabel {
                kind: ScreenLocker.Authenticator.Smartcard
                label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your smartcard)")
            }
        }
    }
}
