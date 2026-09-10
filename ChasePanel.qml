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
  property bool helpOpen: false

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

  // Hand Omastorm's view to HookEcho from outside Omastorm: bin/chase-open
  // reads Omastorm's view export and opens HookEcho's deep link. Its one
  // line of output (the link, or why not) lands in the note.
  function handoff() {
    if (sessionProcess.running || root.pluginDir === "") return
    root.note = "…"
    sessionProcess.command = ["python3", root.pluginDir + "/bin/chase-open"]
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

  // The one thing to do next, derived from the state on screen. A panel that
  // reports "GPS off" and stops there leaves the user to guess the command.
  function hintText() {
    var g = root.snap.gps || {}
    var v = root.snap.viewer || {}
    if (g.state === "off") return "Start gpsd: bash scripts/setup-gpsd.sh"
    if (g.state === "nodevice") return "Plug the receiver in where it sees sky · docs/gps-receivers.md"
    if (g.state === "nofix") return "Waiting on satellites — needs open sky, minutes from cold"
    if (!v.running) return "Start session launches HookEcho and the NMEA bridge together"
    return ""
  }

  // What this is, then the glyph legend — behind `?`. Someone opening this
  // months later should not have to read the repository to place it, and the
  // widget has room for two marks with no room to say what they mean.
  readonly property string legendText:
    "omarchy-chase runs one storm-chase session on this desktop: it points\n" +
    "HookEcho and Supercell Wx at one GPS through gpsd, and starts and stops\n" +
    "them together. It draws no weather itself — the viewers do that.\n" +
    "\n" +
    "Bar glyph: ● session running · ○ idle\n" +
    "GPS mark: + fix · … acquiring · × no receiver · – gpsd off\n" +
    "Esc closes · ? toggles this help"

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
      onTextKey: function(t) { if (t === "?" || t === "/") root.helpOpen = !root.helpOpen }

      ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Style.space(8)

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Chase session"
            color: Color.foreground
            font.pixelSize: Style.font.body
            font.family: Style.font.family
            Layout.fillWidth: true
          }
          Text {
            text: "?"
            color: root.helpOpen ? Color.accent : Color.foreground
            opacity: root.helpOpen ? 1 : .6
            font.pixelSize: Style.font.body
            font.family: Style.font.family
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.helpOpen = !root.helpOpen
            }
          }
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
        Text {
          text: root.hintText()
          visible: !root.helpOpen && text !== ""
          color: Color.foreground
          opacity: .55
          font.pixelSize: Style.font.bodySmall
          font.family: Style.font.family
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }
        Text {
          text: root.legendText
          visible: root.helpOpen
          color: Color.foreground
          opacity: .7
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
          Button {
            text: "Open in HookEcho"
            tooltipText: "Hand Omastorm's view on screen to HookEcho"
            onClicked: root.handoff()
          }
        }
      }
    }
  }
}
