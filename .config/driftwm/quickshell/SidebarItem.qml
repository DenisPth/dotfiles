import QtQuick
import QtQuick.Layouts

// A settings-sidebar row: full pill background when selected or hovered,
// left-aligned icon+text — unlike ListRow (built for a detail+action row), a
// sidebar entry is just a label (optionally with a leading glyph).
Item {
    id: root

    property string text
    property string icon: ""
    property bool highlighted: false
    signal clicked()

    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.fg
        opacity: mouse.containsMouse ? Theme.hoverOpacity : root.highlighted ? 0.12 : 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            text: root.icon
            visible: root.icon !== ""
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }

        Text {
            Layout.fillWidth: true
            text: root.text
            color: Theme.fg
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: root.highlighted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
