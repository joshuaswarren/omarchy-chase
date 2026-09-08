# omarchy-chase

Storm-chasing glue for the [Omarchy](https://omarchy.org) desktop. Not a radar
app. It installs, configures, and connects the weather tools that already
exist, and shows the device and network state a chaser needs beside them.

Status: planning. Nothing here is installable yet. The roadmap is in
[ROADMAP.md](ROADMAP.md).

## What it is for

A chase laptop runs several programs and devices at once: a radar viewer, a
GPS receiver, a cellular or tethered connection, a recording setup, sometimes
a radio. Each program is good at its own job on any desktop. What is missing
is the part that only makes sense on this desktop: getting them installed
together, pointed at the same GPS, aware of the same network condition, and
started and stopped as one session.

That part is this repository. The weather work itself goes upstream.

## The three pieces

| Responsibility | Where it lives |
| --- | --- |
| Decode radar, render products, handle warnings, cache weather data | The chosen weather viewer, [HookEcho](https://github.com/d4vid87/hookecho) first, with [Supercell Wx](https://supercell-wx.readthedocs.io) as the comparison |
| The quick, native radar view in the bar, and the hand-off to a fuller viewer | [Omastorm](https://github.com/wesleygrimes/omastorm) |
| Install and configure the chosen tools, prepare workspaces, show GPS and network status, start and stop a chase session | omarchy-chase |

The dividing question for any feature:

> Would this still make sense for someone using the weather viewer on another
> desktop?

If yes, it belongs upstream in that viewer. If it is about how several
programs and devices work together on Omarchy, it belongs here. Some needs
split: the desktop exposes a condition (a metered connection), the viewer owns
how its fetching responds.

## What it will not do

- Decode or render radar. No second engine, no shared weather daemon. A daemon
  becomes worth proposing only when two real consumers need the same
  capability and the viewer's own export cannot supply it.
- Screen-scrape a viewer or read its private files. State that the bar needs
  and the viewer does not export gets added upstream as a supported export,
  then consumed here.
- Support every viewer through an adapter framework. One viewer is supported
  at a time; the boundary stays clean enough to add a second when a real need
  appears.
- Write Omarchy or system configuration silently. The same rule Omastorm
  follows: read theme and settings, write only under this project's own
  directories, and print any line the user must add by hand.

## Interfaces it builds on

HookEcho exposes, as documented in its
[technical reference](https://github.com/d4vid87/hookecho/blob/main/docs/technical-reference.md):

- `hookecho://goto/SITE,lon,lat,zoom[,time]` deep links, registered on
  Linux through `x-scheme-handler/hookecho` in its `.desktop` file, and
  accepted as an argument that a running instance takes over.
- `hookecho --serve` with `/status.json`, `/alerts.json`, `/obs.json`, and
  `hookecho --status --json`.
- Desktop `gpsd` support, chase mode, offline basemap packs, saved
  workspaces.

Supercell Wx documents GPS through an operating-system provider or an external
NMEA source; its `gpsd` route needs `gpspipe` and `socat`, which is the kind of
setup friction this project exists to remove.

Each of these is a documented interface, verified against source before it is
relied on. Where one turns out not to carry what the desktop needs, the fix is
an upstream issue or pull request, recorded in the roadmap.

## Install

HookEcho (pinned in `hookecho.release.pin`, verified by sha256 on every
install):

```sh
bash scripts/install-hookecho.sh
```

This places the AppImage under `~/.local/share/omarchy-chase/bin`, links
`hookecho` on PATH through `~/.local/bin`, and registers a `.desktop`
entry for `x-scheme-handler/hookecho` so `hookecho://goto/` links open it.
Remove symmetrically:

```sh
bash scripts/install-hookecho.sh --remove
```

## Related

- [Omastorm](https://github.com/wesleygrimes/omastorm), the Omarchy radar
  plugin this project hands off from.
- [HookEcho](https://github.com/d4vid87/hookecho), the first supported
  full viewer.
- [Supercell Wx](https://github.com/dpaulat/supercell-wx), the comparison
  and fallback.

## License

MIT, see [LICENSE](LICENSE).
