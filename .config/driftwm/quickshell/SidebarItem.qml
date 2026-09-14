import QtQuick

// A settings-sidebar row: full pill background when selected or hovered,
// left-aligned text — unlike ListRow (built for a detail+action row), a
// sidebar entry is just a label.
Item {
    id: root

    property string text
    property bool highlighted: false
    signal clicked()

    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.fg
        opacity: mouse.containsMouse ? Theme.hoverOpacity : root.highlighted ? 0.12 : 0
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Theme.fg
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: root.highlighted
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
