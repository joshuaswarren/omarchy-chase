import QtQuick
import Quickshell.Io
import qs.Commons

// Chase bar widget: one glyph summarising the session. Filled dot while a
// session is active, GPS state beside it. Click opens the session panel.
// Helper and scripts resolve beside the installed plugin copy, in the shape
// of fleet-shepherd's BarWidget.
Item {
  id: root

  property var bar: null
  property string moduleName: "io.github.joshuaswarren.chase"
  property var settings: ({})

  readonly property string pluginDir: {
    var url = String(Qt.resolvedUrl("."))
    if (url.indexOf("file://") === 0) url = url.substring(7)
    if (url.indexOf("localhost/") === 0) url = url.substring(9)
    try { url = decodeURIComponent(url) } catch (e) { }
    return url.replace(/\/+$/, "")
  }
  readonly property string helper: pluginDir + "/bin/chase-status"

  property var snap: ({})
  property string glyph: "○ chase"

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground

  implicitWidth: label.implicitWidth + 24
  implicitHeight: root.bar ? root.bar.barSize : 26

  function refresh() {
    if (snapshotProcess.running) return
    snapshotProcess.command = ["python3", root.helper]
    snapshotProcess.running = true
  }

  Component.onCompleted: refresh()

  Timer { interval: 30000; repeat: true; running: true; onTriggered: root.refresh() }

  Process {
    id: snapshotProcess
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var next = JSON.parse(String(text || "{}"))
          root.snap = next
          var gps = (next.gps && next.gps.state) || "off"
          var dot = next.session && next.session.active ? "●" : "○"
          var mark = gps === "fix" ? "+" : gps === "nofix" ? "…" : gps === "nodevice" ? "×" : "–"
          root.glyph = dot + " chase " + mark
        } catch (e) { console.warn("chase", "snapshot was malformed") }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("chase", String(text).trim())
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: mouse.containsPress ? Color.accent : "transparent"
    opacity: mouse.containsMouse && !mouse.containsPress ? 0.75 : 1

    Text {
      id: label
      anchors.centerIn: parent
      color: (root.snap.session && root.snap.session.active) ? Color.accent : root.foreground
      text: root.glyph
      font.pixelSize: 12
      font.family: root.bar && root.bar.fontFamily ? root.bar.fontFamily : "monospace"
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (toggleProcess.running) return
        toggleProcess.command = ["omarchy-shell", "shell", "toggle", root.moduleName]
        toggleProcess.running = true
      }
    }
  }

  Process {
    id: toggleProcess
    running: false
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("chase", String(text).trim())
    }
  }
}
