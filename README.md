# omarchy-chase

Storm-chasing tools for the [Omarchy](https://omarchy.org) desktop. Install
HookEcho, share a GPS receiver through `gpsd`, and see GPS, network and viewer
state in the bar. Radar decoding and weather data stay in the weather apps.

This is an early beta. The HookEcho installer, GPS setup and session panel
are implemented. See the [roadmap](ROADMAP.md) for remaining work.

## Install the bar widget

```sh
omarchy plugin add https://github.com/joshuaswarren/omarchy-chase --enable
```

Click the widget to open the session panel. It shows GPS, network, metered
connection status, viewer state and alert count, with session Start/Stop
controls. Press `Esc` to close it; `?` explains the panel and its symbols.

The GPS mark is `+` for a fix, `…` while acquiring, `×` for no receiver and
a dash when gpsd is off. The filled dot indicates a running session.

## Install HookEcho

The pinned HookEcho AppImage is **x86_64 only**. The install script refuses
other architectures. It checks the download against the SHA256 in
[`hookecho.release.pin`](hookecho.release.pin).

For the setup scripts, clone this repository and run commands from its root:

```sh
git clone https://github.com/joshuaswarren/omarchy-chase.git
cd omarchy-chase
bash scripts/install-hookecho.sh
```

The default install puts the AppImage under `~/.local/share/omarchy-chase/bin`,
links `~/.local/bin/hookecho`, and registers the `hookecho://` URL handler.
The data directory follows `XDG_DATA_HOME` if set.

To remove those installed files:

```sh
bash scripts/install-hookecho.sh --remove
```

## Set up GPS

Use one receiver through `gpsd` so viewers can share it. See
[GPS receiver notes](docs/gps-receivers.md) for hardware and USB advice.

```sh
bash scripts/setup-gpsd.sh
./bin/chase-gps
```

This script uses `sudo`: it installs `gpsd` with pacman if missing and enables
`gpsd.socket`. For a detected u-blox receiver without a device node, it also
loads `cdc_acm` and writes `/etc/modules-load.d/omarchy-chase-gps.conf` so the
module loads on later boots. Review the [script](scripts/setup-gpsd.sh) before
running it. If USB hotplug misses the receiver, pass its actual device path:

```sh
bash scripts/setup-gpsd.sh /dev/ttyACM0
```

In HookEcho, choose Chase > Connect GPS (gpsd). The daemon uses port 2947.

### Supercell Wx

The NMEA bridge supplies a loopback network source for Supercell Wx:

```sh
bash scripts/nmea-bridge.sh start
```

Launch Supercell Wx once, then **close it** before configuring it:

```sh
bash scripts/configure-supercell.sh
```

This rewrites its `settings.json`: GPS plugin `nmea`, source
`socket://127.0.0.1:2948`, and Track Location enabled. The default file is
`~/.local/share/Supercell Wx/settings.json`; `SCWX_SETTINGS` overrides it.
The script refuses to proceed while a `supercell-wx` process is running.

## Open Omastorm's view in HookEcho

With [Omastorm](https://github.com/wesleygrimes/omastorm) exporting its view to
`~/.local/state/omastorm/state.json`, run:

```sh
./bin/chase-open
./bin/chase-open --print   # show the deep link without opening it
```

The panel's Open in HookEcho button uses the same command. A live view
opens live; a historical frame includes its scan time in the deep link.
Omastorm itself does not launch the other viewer.

## Related projects

- [HookEcho](https://github.com/d4vid87/hookecho): the first supported full viewer.
- [Omastorm](https://github.com/wesleygrimes/omastorm): the native radar view in the bar.
- [Supercell Wx](https://github.com/dpaulat/supercell-wx): another weather viewer.

## Support

[Sponsor on GitHub](https://github.com/sponsors/joshuaswarren) or use the
existing Lightning address `joshuaswarren@strike.me`.

## License

MIT. See [LICENSE](LICENSE).
