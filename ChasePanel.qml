import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Ui

// Chase session popup: GPS, network and viewer state as reported (never
// scraped), plus session start/stop. State comes from bin/chase-status;
// actions run scripts/chase-session.sh. It renders no weather.
//
// Built on the shared Panel/KeyboardPanel pair like the first-party
// panels: that supplies the open/close lifecycle, anchoring under the bar
// button, outside-click dismissal, and Escape — none of which a bare
// PanelWindow gets right.
Panel {
  id: root
  moduleName: "io.github.joshuaswarren.chase"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property string helper: ""
  property string pluginDir: ""
  readonly property string sessionScript: pluginDir + "/scripts/chase-session.sh"

  property var snap: ({})
  property string note: ""

  function refresh() {
    if (snapshotProcess.running || root.helper === "") return
    snapshotProcess.command = ["python3", root.helper]
    snapshotProcess.running = true
  }

  function session(action) {
    if (sessionProcess.running || root.pluginDir === "") return
    root.note = "…"
    sessionProcess.command = ["bash", root.sessionScript, action]
    sessionProcess.running = true
  }

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

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.session("start")
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Style.space(8)

        Text {
          text: "Chase session"
          color: Color.foreground
          font.pixelSize: Style.font.body
          font.family: Style.font.family
        }
        Text { text: root.gpsText(); color: Color.foreground; opacity: .75; font.pixelSize: Style.font.bodySmall; font.family: Style.font.family }
        Text { text: root.netText(); color: Color.foreground; opacity: .75; font.pixelSize: Style.font.bodySmall; font.family: Style.font.family }
        Text { text: root.viewerText(); color: Color.foreground; opacity: .75; font.pixelSize: Style.font.bodySmall; font.family: Style.font.family }
        Text {
          text: root.note
          visible: root.note !== ""
          color: Color.accent
          font.pixelSize: Style.font.bodySmall
          font.family: Style.font.family
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        RowLayout {
          spacing: Style.space(8)
          Button {
            text: "Start session"
            onClicked: root.session("start")
          }
          Button {
            text: "Stop"
            onClicked: root.session("stop")
          }
        }
      }
    }
  }
}
