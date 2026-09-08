import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Chase session panel: GPS, network and viewer state as reported (never
// scraped), plus session start/stop. State comes from bin/chase-status;
// actions run scripts/chase-session.sh. Rendering no weather is the point.
// Drops down from the top edge in the shape of omaloop's panel.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  readonly property string pluginId: "io.github.joshuaswarren.chase"
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

  readonly property color background: Color.background
  readonly property color foreground: Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Color.muted

  readonly property int sheetW: 380
  readonly property int sheetH: 300

  function refresh() {
    if (snapshotProcess.running) return
    snapshotProcess.command = ["python3", root.helper]
    snapshotProcess.running = true
  }
  // Summoned by the shell (toggle/summon); hidden by close. `opened` drives
  // the window, the refresh timer, and the shell's isOpen readback.
  function open(payloadJson) { root.opened = true; root.refresh() }
  function close() { root.opened = false }

  function session(action) {
    if (sessionProcess.running) return
    root.note = ""
    sessionProcess.command = ["bash", root.sessionScript, action]
    sessionProcess.running = true
  }

  onOpenedChanged: {
    if (root.opened) {
      root.refresh()
      Qt.callLater(function() { if (root.opened) keyCatcher.forceActiveFocus() })
    }
  }
  Item {
    id: keyCatcher
    focus: true
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
    }
  }
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

  PanelWindow {
    id: window
    visible: root.opened
    anchors { top: true; left: false; right: false; bottom: false }
    implicitWidth: root.sheetW
    implicitHeight: root.sheetH
    color: "transparent"
    WlrLayershell.namespace: "chase"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.background
      border.color: root.accent
      border.width: 1
      radius: Style.cornerRadius

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          Text { text: "Chase session"; color: root.foreground; font.pixelSize: 16; Layout.fillWidth: true }
          Text {
            text: "×"; color: root.dim; font.pixelSize: 18
            MouseArea {
              anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
            }
          }
        }
        Text { text: root.gpsText(); color: root.dim; font.pixelSize: 12 }
        Text { text: root.netText(); color: root.dim; font.pixelSize: 12 }
        Text { text: root.viewerText(); color: root.dim; font.pixelSize: 12 }
        Text { text: root.note; color: root.accent; font.pixelSize: 12; visible: root.note !== "" }

        RowLayout {
          spacing: 8
          Rectangle {
            implicitWidth: 120; implicitHeight: 32; radius: Style.cornerRadius; color: root.accent
            Text { anchors.centerIn: parent; text: "Start session"; color: root.background }
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
        Item { Layout.fillHeight: true }
      }
    }
  }
}
