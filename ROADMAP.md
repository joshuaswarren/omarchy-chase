# Roadmap

Ordered by dependency, not by date. Each step names the receipt that closes
it: a recording, a merged change, a command output. A step opens when the one
before it has its receipt, and the failures seen on real hardware decide what
the next step is. Nothing here is committed to beyond the step in progress.

## 0. Hand-off: Omastorm to HookEcho

The first receipt, and the one that tests whether the three projects can
collaborate at all before anything new is built.

- [x] Omastorm builds HookEcho's `hookecho://goto/` link from the station,
      map centre, zoom, and (when not live) the scan time on screen, and opens
      it. Pull request `wesleygrimes/omastorm#17` from branch
      `hookecho-handoff`.
- [x] Verified on esper (Omarchy, Arch) with HookEcho v0.12.0-beta.2 as the
      AppImage: the site and centre transfer, a live view opens live, a
      stepped-back frame opens on that scan. Receipt: `check.sh` 15/15 plus
      the live / stepped-back / off-PATH runs in the PR body.
- [ ] Any mismatch found (zoom scale, time handling, scheme registration on
      Arch) filed upstream against the project that owns it.

## 1. Install HookEcho on Omarchy

HookEcho ships `.deb`, AppImage, and Windows installers; Arch has no package
(AUR checked 2026-09-08). Omarchy is Arch.

- [x] A script that fetches the pinned AppImage release, verifies its
      checksum, places it under `~/.local/share/omarchy-chase/bin`, and puts
      `hookecho` on PATH plus a `.desktop` entry that registers
      `x-scheme-handler/hookecho`, in the shape Omastorm's
      `scripts/install-engine.sh` and `scripts/install-launcher.sh` use.
      (`scripts/install-hookecho.sh`, pin in `hookecho.release.pin`.)
- [x] Removal is documented and symmetrical (`--remove`, README).
- [x] Receipt: `xdg-mime query default x-scheme-handler/hookecho` names
      HookEcho, and `xdg-open 'hookecho://goto/KTLX'` opens it (verified on
      esper 2026-09-08: `opening link hookecho://goto/KTLX`, `live stream
      started for KTLX`).
- [ ] Decide whether an AUR package belongs upstream; if so, propose it there
      rather than maintaining one here.

## 2. One GPS source for everything

- [ ] `gpsd` set up for the receivers actually on the chase laptop, with a
      status check that says fix / no fix / no device.
- [ ] HookEcho pointed at that `gpsd`, using its documented desktop support.
- [ ] Supercell Wx pointed at the same `gpsd` through the documented
      `gpspipe` and `socat` route, scripted so the user does not assemble it.
      If the maintainers agree, propose a direct `gpsd` source upstream and
      retire the script.
- [ ] Receipt: both viewers follow the same moving position in a recorded
      drive, and a pulled receiver shows as lost in the status check.

## 3. Chase session and status in the bar

A small Quickshell panel in the Omarchy bar, in Omastorm's plugin shape. It
shows state and starts or stops a session; it renders no weather.

- [ ] Session start and stop: launch the viewer on a saved workspace, start
      GPS, start any recording, and stop them together.
- [ ] Status: GPS fix, which network connection is active and whether it is
      metered, viewer running or not.
- [ ] Viewer state that the bar needs and HookEcho exports today
      (`/status.json`, `/alerts.json`) shown as-is. State it does not export is
      added upstream as a supported export first, then consumed; never read
      from private files.
- [ ] Receipt: a recorded session from a cold desktop to a running chase and
      back, with the bar showing every transition.

## 4. Connectivity behaviour

- [ ] The desktop exposes the connection condition (active interface,
      metered, offline) in a form the viewers can read.
- [ ] Reconnect and metered-download behaviour is filed and fixed upstream in
      the viewer that owns the fetching; this project only supplies the
      condition.
- [ ] Receipt: a drive through a coverage gap, recorded, with the viewer
      resuming correctly and the bar showing the gap.

## 5. Second viewer

Opens only when testing shows a workflow HookEcho cannot reasonably support.
Supercell Wx is the candidate. The boundary from steps 1 to 4 must hold
without an adapter framework; if it needs one, that is a design failure to fix
first.

## Not planned

- A new standalone chase application. Reconsidered only after step 4 shows a
  workflow the existing viewers cannot support.
- A shared weather daemon (`stormd`). Reconsidered only when two real consumers
  need the same capability and the viewer's export is the wrong fit.
- Forecasts or mosaics in Omastorm; its scope is decided in its own design
  document.

## Upstream log

Every change proposed to another project, with its receipt.

| Date | Project | Change | Receipt |
| --- | --- | --- | --- |
| 2026-09-08 | Omastorm | `Shift+O` / HOOKECHO control opens the view in HookEcho | `wesleygrimes/omastorm#17` from branch `hookecho-handoff`; verified on esper (`check.sh` 15/15, live / stepped-back / off-PATH) |
