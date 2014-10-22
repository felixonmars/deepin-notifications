import QtQuick 2.1
import QtGraphicalEffects 1.0
import Deepin.Widgets 1.0

Item {
    id: bubble
    y: - height
    width: content.width + 20 + 24 * 2
    height: content.height + 20
    layer.enabled: true

    property var notificationObj

    signal actionInvoked(int id, string action_id)
    signal dismissed(int id)
    signal expired(int id)

    function containsMouse() {
        var pos = _bubble.getCursorPos()
        var x = pos.x - _bubble.x
        var y = pos.y - _bubble.y
        return 0 <= x && x <= width && 0 <= y && y <= height
    }

    PropertyAnimation {
        id: in_animation

        running: true
        target: bubble
        property: "y"
        to: 0
        duration: 300
        easing.type: Easing.OutCubic

        onStopped: out_timer.restart()
    }

    ParallelAnimation {
        id: out_animation

        PropertyAnimation {
            target: bubble
            property: "x"
            to: width
            duration: 500
            easing.type: Easing.OutCubic
        }

        PropertyAnimation {
            target: bubble
            property: "opacity"
            to: 0.2
            duration: 500
            easing.type: Easing.OutCubic
        }

        onStopped: bubble.expired(notificationObj.id)
    }

    Timer {
        id: mouse_in_check_timer
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            if (bubble.containsMouse()) {
                close_button.visible = true
            } else {
                close_button.visible = false
            }
        }
    }

    Timer {
        id: out_timer

        interval: 3500
        onTriggered: {
            if (bubble.containsMouse()) {
                out_timer.restart()
            } else {
                out_animation.start()
            }
        }
    }

    function _processContentBody(body) {
        var result = body

        result = result.replace("\n", "<br>")

        return result
    }

    function updateContent(content) {
        if (x != 0 || opacity != 1) {
            x = 0
            opacity = 1
            y = -height
            in_animation.start()
        }
        out_timer.restart()

        notificationObj = JSON.parse(content)
        icon.icon = notificationObj.image_path || notificationObj.app_icon || "ooxx"
        summary.text = notificationObj.summary
        body.text = _processContentBody(notificationObj.body)

        action_button_area.actionOne = ""
        action_button_area.actionTwo = ""
        action_button_area.idOne = ""
        action_button_area.idTwo = ""

        var count = 0
        for (var i = 0; i < notificationObj.actions.length; i += 2) {
            if (i + 1 < notificationObj.actions.length
                && notificationObj.actions[i + 1] != "default") {
                if (count == 0) {
                    // there's image action that we support
                    if (action_image_button.supportedTypes.indexOf(notificationObj.actions[i]) != -1) {
                        action_image_button.state = notificationObj.actions[i]
                        break
                    } else {
                        action_button_area.actionOne = notificationObj.actions[i + 1]
                        action_button_area.idOne = notificationObj.actions[i]
                    }
                } else if (count == 1) {
                    action_button_area.actionTwo = notificationObj.actions[i + 1]
                    action_button_area.idTwo = notificationObj.actions[i]
                }
                count++
            }
        }
    }

    RectangularRing {
        id: ring
        visible: false
        outterWidth: innerWidth + 2
        outterHeight: innerHeight + 3
        outterRadius: content.radius + 2
        innerWidth: content.width
        innerHeight: content.height
        innerRadius: content.radius

        verticalCenterOffset: -2

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2
    }

    GaussianBlur {
        anchors.fill: ring
        source: ring
        radius: 8
        samples: 16
        transparentBorder: true
    }

    Rectangle {
        id: content
        radius: 4
        width: 300
        height: 70
        anchors.centerIn: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.75)}
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85)}
        }

        Rectangle {
            id: bubble_border
            radius: 4
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.7)
            anchors.fill: parent

            Rectangle {
                id: bubble_inner_border
                radius: 4
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.1)

                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                anchors.leftMargin: 1
                anchors.rightMargin: 1
            }

            Item {
                id: bubble_bg
                anchors.fill: bubble_inner_border

                Item {
                    id: icon_place_holder
                    width: 70
                    height: 70

                    DIcon {
                        id: icon
                        width: 48
                        height: 48
                        theme: "Deepin"

                        anchors.centerIn: parent
                    }
                }

                Text {
                    id: summary
                    width: 200
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    textFormat: Text.StyledText
                    color: Qt.rgba(1, 1, 1, 0.5)

                    anchors.left: icon_place_holder.right
                    anchors.top: icon_place_holder.top
                    anchors.topMargin: (icon_place_holder.height - icon.height) / 2
                }

                Text {
                    id: body_flickable_place_holder
                    text: "something text which are able to  inflat the two lines of this place holder"
                    visible: false
                    wrapMode: body.wrapMode
                    textFormat: body.textFormat
                    font.pixelSize: body.font.pixelSize
                    maximumLineCount: 2

                    anchors.left: summary.left
                    anchors.right: parent.right
                    anchors.rightMargin: 30
                    anchors.top: summary.bottom
                    anchors.topMargin: 3
                }

                Flickable {
                    clip: true
                    anchors.fill: body_flickable_place_holder
                    contentWidth: width
                    contentHeight: body.implicitHeight

                    Text {
                        id: body
                        width: parent.width
                        height: parent.height
                        color: "white"
                        wrapMode: Text.WrapAnywhere
                        linkColor: "#19A9F9"
                        textFormat: Text.StyledText
                        font.pixelSize: 11

                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
            }

            LinearGradient {
                id: bubble_bg_mask
                visible: false
                anchors.fill: bubble_bg

                start: action_button_area.visible ? Qt.point(action_button_area.x - 30, 0)
                                                  : Qt.point(action_image_button.x - 15, 0)
                end: action_button_area.visible ? Qt.point(action_button_area.x, 0)
                                                : Qt.point(action_image_button.x + 10, 0)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1)}
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0)}
                }
            }

            OpacityMask {
                id: opacity_mask
                visible: action_button_area.visible || action_image_button.visible
                anchors.fill: bubble_bg
                source: ShaderEffectSource { sourceItem: bubble_bg; hideSource: opacity_mask.visible }
                maskSource: ShaderEffectSource { sourceItem: bubble_bg_mask; hideSource: opacity_mask.visible }
            }

            MouseArea {
                hoverEnabled: true
                anchors.fill: bubble_bg

                onClicked: {
                    var default_action_id
                    for (var i = 0; i < notificationObj.actions.length; i += 2) {
                        if (notificationObj.actions[i + 1] == "default") {
                            default_action_id = notificationObj.actions[i]
                        }
                    }
                    print(default_action_id)
                    if (default_action_id) { bubble.actionInvoked(notificationObj.id, default_action_id) }
                    bubble.dismissed(notificationObj.id)
                }
            }

            ActionButton {
                id: action_button_area

                onAction: {
                    bubble.actionInvoked(notificationObj.id, actionId)
                    bubble.dismissed(notificationObj.id)
                }

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            ActionImageButton {
                id: action_image_button

                onAction: {
                    bubble.actionInvoked(notificationObj.id, actionId)
                    bubble.dismissed(notificationObj.id)
                }

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }

            CloseButton {
                id: close_button
                visible: false
                anchors.top: bubble_bg.top
                anchors.right: bubble_bg.right
                anchors.topMargin: 5
                anchors.rightMargin: 6

                onClicked: bubble.dismissed(notificationObj.id)
            }
        }
    }
}
