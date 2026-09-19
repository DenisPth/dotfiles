import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // "24" or "12" — set from Settings > время, defaults to 24h.
    property string hourFormat: "24"
    readonly property string timeFormat: root.hourFormat === "12" ? "h:mm AP" : "HH:mm"

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

    FileView {
        id: formatFile
        path: Quickshell.shellDir + "/clock_format.txt"
        printErrors: false
        watchChanges: true
        onLoaded: {
            const v = text().trim()
            if (v === "12" || v === "24") root.hourFormat = v
        }
        onFileChanged: reload()
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -10
        anchors.rightMargin: -10
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        radius: 8
        color: Theme.fg
        opacity: mouse.containsMouse ? Theme.hoverOpacity : 0
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, root.timeFormat)
            color: Theme.fg
            font.pixelSize: 44
            font.family: Theme.fontFamily
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: calendar.toggle()
    }

    Popover {
        id: calendar
        target: root
        onVisibleChanged: if (visible) month.shown = clock.date

        MonthView {
            id: month
            today: clock.date
        }
    }
}
