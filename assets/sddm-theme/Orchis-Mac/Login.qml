import org.kde.breeze.components

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import Qt5Compat.GraphicalEffects 1.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as PlasmaCore

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox
    property bool showUsernamePrompt: !showUserList
    property int usernameFontSize
    property int fontSize: parseInt(config.fontSize)
    property string usernameFontColor
    property string lastUserName
    property bool loginScreenUiVisible: false
    property bool passwordFieldOutlined: config.PasswordFieldOutlined == "true"
    property bool hidePasswordRevealIcon: config.HidePasswordRevealIcon == "false"
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    onUserSelected: {
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text

        footer.enabled = false
        mainStack.enabled = false
        userListComponent.userList.opacity = 0.5

        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(360, root.width * 0.9)
        Layout.maximumWidth: 360
        Layout.margins: Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Kirigami.Units.largeSpacing
                visible: !showUsernamePrompt && userList.selectedUser
                text: userList.selectedUser
                color: "#FFFFFF"
                font.pointSize: fontSize + 4
                font.weight: Font.Normal
                font.family: config.Font || "Inter"
            }

            Input {
                id: userNameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: Kirigami.Units.largeSpacing
                font.pointSize: fontSize + 1
                font.family: config.Font || "Inter"
                text: lastUserName
                visible: showUsernamePrompt
                focus: showUsernamePrompt && !lastUserName
                placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Username")
                placeholderTextColor: "#6B6B6B"
                color: "#FFFFFF"
                selectionColor: "#2563EB"
                selectedTextColor: "#FFFFFF"
                leftPadding: 16
                rightPadding: 16
                background: Rectangle {
                    radius: 6
                    border.width: 1
                    border.color: userNameInput.activeFocus ? "#2563EB" : "#3F3F3F"
                    color: "#1A1A1A"
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                }
                onAccepted: passwordBox.forceActiveFocus()
            }

            Item {
                id: passwordFieldContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.bottomMargin: Kirigami.Units.largeSpacing

                Input {
                    id: passwordBox
                    anchors.fill: parent
                    font.pointSize: fontSize + 1
                    font.family: config.Font || "Inter"
                    placeholderText: (config.PasswordFieldPlaceholderText === "Password" || !config.PasswordFieldPlaceholderText) ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Password") : config.PasswordFieldPlaceholderText
                    focus: !showUsernamePrompt || lastUserName
                    echoMode: TextInput.Password
                    onAccepted: startLogin()
                    placeholderTextColor: "#6B6B6B"
                    passwordCharacter: (config.PasswordFieldCharacter === "" || !config.PasswordFieldCharacter) ? "●" : config.PasswordFieldCharacter
                    color: "#FFFFFF"
                    selectionColor: "#2563EB"
                    selectedTextColor: "#FFFFFF"
                    leftPadding: 16
                    rightPadding: loginButton.width + 12
                    background: Rectangle {
                        radius: 6
                        border.width: 1
                        border.color: passwordBox.activeFocus ? "#2563EB" : "#3F3F3F"
                        color: "#1A1A1A"
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }

                    Keys.onEscapePressed: {
                        mainStack.currentItem.forceActiveFocus();
                    }

                    Keys.onPressed: {
                        if (event.key == Qt.Key_Left && !text) {
                            userList.decrementCurrentIndex();
                            event.accepted = true
                        }
                        if (event.key == Qt.Key_Right && !text) {
                            userList.incrementCurrentIndex();
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
                        target: sddm
                        onLoginFailed: {
                            passwordBox.selectAll()
                            passwordBox.forceActiveFocus()
                        }
                    }
                }

                Item {
                    id: loginButton
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    opacity: 0
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
                        source: "assets/login.svgz"
                        sourceSize: Qt.size(16, 16)
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { buttonBg.color = "#1D4ED8" }
                        onExited: { buttonBg.color = "#2563EB" }
                        onPressed: { buttonBg.color = "#1E40AF" }
                        onReleased: { buttonBg.color = "#2563EB"; startLogin(); }
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
        }
    }
}
