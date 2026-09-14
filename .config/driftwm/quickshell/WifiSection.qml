import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

// Same nmcli shape as Network.qml's popover, trimmed: this window is opened
// deliberately (not always on screen), so a plain poll while visible replaces
// the tile's background `nmcli monitor` + debounce dance.
ColumnLayout {
    id: root
    spacing: 6

    property bool radio: false
    property bool available: false
    property var networks: []
    property string pending: ""
    property string error: ""

    // `visible` starts true for the default section (wifi), so there's no
    // false→true transition to catch on open — onCompleted covers that case,
    // onVisibleChanged covers switching back to this tab later.
    Component.onCompleted: if (visible) { poll.running = true; refresh(true) }
    onVisibleChanged: {
        pending = ""
        error = ""
        poll.running = visible
        if (visible) refresh(true)
    }

    // LC_ALL=C: nmcli's ACTIVE column is "sí/да/…" under a non-English
    // locale, which broke matching it against "yes" below.
    function refresh(rescan) {
        refresher.command = ["sh", "-c", `LC_ALL=C nmcli radio wifi; echo @@; LC_ALL=C nmcli -t -e no -f TYPE,STATE,DEVICE dev; echo @@; LC_ALL=C nmcli -t -e no -f TYPE,NAME con show; echo @@; LC_ALL=C nmcli -t -e no -f ACTIVE,SIGNAL,SECURITY,SSID dev wifi list --rescan ${rescan ? "yes" : "no"}`]
        refresher.running = true
    }

    function parse(text) {
        const sections = text.split(/^@@$/m)
        if (sections.length < 4) return
        const [radioText, devices, connections, list] = sections
        root.radio = radioText.trim() === "enabled"
        let hasWifi = false
        for (const line of devices.trim().split("\n")) {
            if (line.split(":")[0] === "wifi") hasWifi = true
        }
        root.available = hasWifi
        const known = new Set()
        for (const line of connections.trim().split("\n")) {
            const type = line.substring(0, line.indexOf(":"))
            if (type === "802-11-wireless") known.add(line.substring(type.length + 1))
        }
        const bySsid = new Map()
        for (const line of list.trim().split("\n")) {
            const parts = line.split(":")
            if (parts.length < 4) continue
            const entry = {
                active: parts[0] === "yes",
                signal: Number(parts[1]),
                security: parts[2],
                ssid: parts.slice(3).join(":"),
            }
            if (!entry.ssid) continue
            entry.known = known.has(entry.ssid)
            const seen = bySsid.get(entry.ssid)
            if (!seen || entry.active || (!seen.active && entry.signal > seen.signal)) bySsid.set(entry.ssid, entry)
        }
        root.networks = [...bySsid.values()].sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal))
    }

    function run(command) {
        if (runner.running) return
        root.error = ""
        root.pending = ""
        runner.command = command
        runner.running = true
    }

    function tap(network) {
        if (network.active) {
            run(["nmcli", "connection", "down", "id", network.ssid])
        } else if (network.known || network.security === "" || network.security.includes("OWE")) {
            run(["nmcli", "device", "wifi", "connect", network.ssid])
        } else {
            root.error = ""
            root.pending = network.ssid
        }
    }

    Process {
        id: refresher
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: runner
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
        onExited: exitCode => root.refresh(false)
    }

    Timer {
        id: poll
        interval: 5000
        repeat: true
        onTriggered: root.refresh(false)
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: "wi-fi"
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.bold: true
            font.family: Theme.fontFamily
        }

        FlatButton {
            text: root.radio ? "on" : "off"
            onClicked: root.run(["nmcli", "radio", "wifi", root.radio ? "off" : "on"])
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        clip: true
        model: root.networks

        delegate: ListRow {
            id: entry
            required property var modelData
            width: ListView.view.width
            text: entry.modelData.ssid
            highlighted: entry.modelData.active
            detail: (entry.modelData.active ? "connected · " : entry.modelData.known ? "saved · " : "") + `${entry.modelData.signal}%`
            action: entry.modelData.known ? "forget" : ""
            onClicked: root.tap(entry.modelData)
            onActionClicked: root.run(["nmcli", "connection", "delete", "id", entry.modelData.ssid])
        }
    }

    Text {
        visible: root.networks.length === 0
        text: root.available ? (root.radio ? "ищем сети…" : "wi-fi выключен") : "адаптер не найден"
        color: Theme.fg
        opacity: Theme.dim
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    RowLayout {
        visible: root.pending !== ""
        Layout.fillWidth: true
        spacing: 6

        TextField {
            id: password
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: `пароль для ${root.pending}`
            placeholderTextColor: Theme.border
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            background: Rectangle { color: Theme.track; radius: 6 }
            onVisibleChanged: if (visible) {
                text = ""
                forceActiveFocus()
            }
            onAccepted: join.clicked()
        }

        FlatButton {
            id: join
            text: "подключить"
            onClicked: root.run(["nmcli", "device", "wifi", "connect", root.pending, "password", password.text])
        }
    }

    Text {
        visible: root.error !== ""
        text: root.error
        color: Theme.fg
        opacity: Theme.dim
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        font.pixelSize: Theme.smallFontSize
        font.family: Theme.fontFamily
    }
}
