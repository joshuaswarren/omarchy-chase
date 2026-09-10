# GPS receivers

One receiver feeds everything: `gpsd` owns the device, HookEcho reads
`gpsd`, and Supercell Wx reads NMEA bridged from `gpsd`. Buy one USB
receiver; do not give each viewer its own.

## Recommended: VK-162

The u-blox 7 "G-mouse" puck, ~$8–15. It appears as `/dev/ttyACM0` with no
drivers, speaks NMEA at 9600 baud out of the box, and `gpsd` hotplugs it.
This is what step 2 was built and tested against.

Caveats, all physical, none software:

- **Plug it through a hub, not a bare laptop port.** On esper (Dell
  Precision, xHCI) the puck enumerated on two different ports with
  `can't set config #1, error -71` and never got a `/dev/ttyACM`; the same
  unit was fine on a Mac and on esper through an Anker USB-C hub. The
  cheap boards drive a marginal full-speed link that a hub re-drives.
  `scripts/setup-gpsd.sh` names this fault when it sees it.
- It ships with its cable attached (~1 m). That is enough to reach the
  dash from a hub on the console; there is nothing to extend.
- Needs real sky. First fix from cold can take minutes; a windowsill works,
  an interior room does not. Judge it only outdoors or on the dash.
- USB-A plug. On USB-C-only machines the hub above covers it.

## Alternatives

- **GlobalSat BU-353-N5**: the current puck in that line (the S4 is
  discontinued). Longer cable, better magnet, ~$40+. Same NMEA workflow;
  if `gpsd` sees it stuck in binary mode, `gpsctl -n` forces NMEA.
- **Any u-blox 8 / M10 USB puck** (VK-172 and its clones): same
  `/dev/ttyACM0` behaviour as the VK-162, usually with faster fixes.
  Fine if the price is close.

## Avoid

- **Prolific-chipset clones** (`/dev/ttyUSB0` no-name serial pucks):
  counterfeit chips, driver flakiness, baud-rate guessing. Not worth the
  $5 saved.
- **Bluetooth GPS**: pairing + rfcomm friction on every session start for
  no benefit inside a car.
- **Phone-as-GPS over USB**: tethering GPS apps exist but add a second
  battery to manage and a second thing to fail at chase time.

## When it arrives

1. Plug it in where it sees sky.
2. `bash scripts/setup-gpsd.sh` (installs `gpsd` if missing, enables the
   socket, attaches the device).
3. `chase-gps status` — expect `no fix` for the first minutes, then
   `fix` with coordinates. Anything else is a setup problem, not a
   waiting problem; see the script's output.
