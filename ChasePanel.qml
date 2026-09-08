import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons

// Chase session panel: GPS, network and viewer state as reported (never
// scraped), plus session start/stop. State comes from bin/chase-status;
// actions run scripts/chase-session.sh. Rendering no weather is the point.
Item {
  id: root

  property var bar: null
  property string moduleName: "io.github.joshuaswarren.chase"
  property var settings: ({})
  property bool opened: false

  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    if (url.indexOf("localhost/") === 0) url = url.substring(9)
    try { url = decodeURIComponent(url) } catch (e) { }
    return url.replace(/\/+$/, "")
  }
  readonly property string helper: pluginDir + "/bin/chase-status"
  readonly property string sessionScript: pluginDir + "/scripts/chase-session.sh"

  property var snap: ({})
  property string note: ""

  readonly property color foreground: Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Color.foreground

  function refresh() {
    if (snapshotProcess.running) return
    snapshotProcess.command = ["python3", root.helper]
    snapshotProcess.running = true
  }

  function session(action) {
    if (sessionProcess.running) return
    root.note = ""
    sessionProcess.command = ["bash", root.sessionScript, action]
    sessionProcess.running = true
  }

  Component.onCompleted: refresh()
  onOpenedChanged: if (root.opened) root.refresh()

  Timer { interval: 10000; repeat: true; running: root.opened; onTriggered: root.refresh() }

  function gpsText() {
    var g = root.snap.gps || {}
    if (g.state === "fix") return "GPS fix · " + g.lat + ", " + g.lon
    if (g.state === "nofix") return "GPS no fix · " + (g.device || "waiting")
    if (g.state === "nodevice") return "GPS no device"
    return "GPS off · gpsd not running"
  }

  function netText() {
    var n = root.snap.net || {}
    if (n.state === "up") return "Net " + (n.connection || "?") + (n.metered ? " · metered" : "")
    if (n.state === "down") return "Net offline"
    return "Net unknown"
  }

  function viewerText() {
    var v = root.snap.viewer || {}
    if (!v.running) return "Viewer stopped"
    var s = "Viewer running"
    if (v.alerts !== null && v.alerts !== undefined) s += " · " + v.alerts + " alert(s)"
    if (v.summary) s += " · " + v.summary
    return s
  }

  Process {
    id: snapshotProcess
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.snap = JSON.parse(String(text || "{}")) }
        catch (e) { console.warn("chase", "snapshot was malformed") }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("chase", String(text).trim())
    }
  }

  Process {
    id: sessionProcess
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text || "").trim()
        if (line !== "") root.note = line
        root.refresh()
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text || "").trim()
        if (line !== "") root.note = line
        root.refresh()
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 8

    Text { text: "Chase session"; color: root.foreground; font.pixelSize: 16 }
    Text { text: root.gpsText(); color: root.dim; font.pixelSize: 12 }
    Text { text: root.netText(); color: root.dim; font.pixelSize: 12 }
    Text { text: root.viewerText(); color: root.dim; font.pixelSize: 12 }
    Text { text: root.note; color: root.accent; font.pixelSize: 12; visible: root.note !== "" }

    RowLayout {
      spacing: 8
      Rectangle {
        implicitWidth: 120; implicitHeight: 32; radius: Style.cornerRadius; color: root.accent
        Text { anchors.centerIn: parent; text: "Start session"; color: Color.background }
        MouseArea {
          anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: root.session("start")
        }
      }
      Rectangle {
        implicitWidth: 120; implicitHeight: 32; radius: Style.cornerRadius
        color: "transparent"; border.color: root.dim; border.width: 1
        Text { anchors.centerIn: parent; text: "Stop"; color: root.foreground }
        MouseArea {
          anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: root.session("stop")
        }
      }
    }
  }
}
