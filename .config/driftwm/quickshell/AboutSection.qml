import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Static-ish system info, gathered once per open — nothing here changes fast
// enough to warrant polling.
ColumnLayout {
    id: root
    spacing: 3

    property string os: ""
    property string kernel: ""
    property string host: ""
    property string cpu: ""
    property string gpu: ""
    property string driftwmVersion: ""
    property string qsVersion: ""

    onVisibleChanged: if (visible) query.running = true

    Process {
        id: query
        command: ["sh", "-c",
            "grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'; echo @@; " +
            "uname -r; echo @@; " +
            "hostname; echo @@; " +
            "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//'; echo @@; " +
            "lspci | grep -i 'vga\\|3d controller' | head -n1 | cut -d: -f3 | sed 's/^ *//'; echo @@; " +
            "driftwm --version; echo @@; " +
            "qs --version"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [os, kernel, host, cpu, gpu, dw, qs] = text.split(/^@@$/m).map(s => s.trim())
                root.os = os || "—"
                root.kernel = kernel || "—"
                root.host = host || "—"
                root.cpu = cpu || "—"
                root.gpu = gpu || "—"
                root.driftwmVersion = dw || "—"
                root.qsVersion = qs || "—"
            }
        }
    }

    component InfoRow: RowLayout {
        property alias label: l.text
        property alias value: v.text
        Layout.fillWidth: true
        spacing: 8

        Text {
            id: l
            Layout.preferredWidth: 70
            color: Theme.fg
            opacity: Theme.dim
            font.pixelSize: Theme.smallFontSize
            font.family: Theme.fontFamily
        }

        Text {
            id: v
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.fg
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
    }

    InfoRow { label: "система"; value: root.os }
    InfoRow { label: "ядро"; value: root.kernel }
    InfoRow { label: "хост"; value: root.host }
    InfoRow { label: "cpu"; value: root.cpu }
    InfoRow { label: "gpu"; value: root.gpu }
    InfoRow { label: "driftwm"; value: root.driftwmVersion }
    InfoRow { label: "quickshell"; value: root.qsVersion }
}
