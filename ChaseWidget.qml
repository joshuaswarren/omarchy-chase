import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Chase bar widget: one glyph summarising the session, and the host for the
// session panel.
//
// Shape follows the first-party clock widget, which is the contract the bar
// enforces: clicks arrive only through a registered WidgetButton, and a
// bar-widget that owns a panel mounts it in a nested Loader and exposes
// open/close/opened on its own root (Bar.findPanelWidget looks there).
BarWidget {
  id: root
  moduleName: "io.github.joshuaswarren.chase"

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

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---- Panel lifecycle. The bar routes summon/hide/toggle here.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("helper" in target) target.helper = root.helper
    if ("pluginDir" in target) target.pluginDir = root.pluginDir
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

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
          if (panelLoader.item) panelLoader.item.snap = next
        } catch (e) { console.warn("chase", "snapshot was malformed") }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("chase", String(text).trim())
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("ChasePanel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
    onStatusChanged: {
      if (status === Loader.Error)
        console.warn("chase: panel failed to load:", sourceComponent ? sourceComponent.errorString() : "")
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    active: root.opened
    tooltipText: "Chase session"
    onPressed: {
      root.refresh()
      root.togglePanel()
    }
  }
}
