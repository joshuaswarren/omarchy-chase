# GPS receivers

Use one receiver through `gpsd`. HookEcho reads it directly; Supercell Wx
reads the NMEA bridge from the same daemon.

## Tested setup

The project was tested with a VK-162 USB puck. On a Dell Precision, the
receiver failed to configure on two direct USB ports with kernel error
`-71`, but worked through an Anker USB-C hub. It also worked on a Mac.
This is a record of that setup, not a requirement for every USB receiver.

On Linux the receiver uses the `cdc_acm` driver and a `/dev/ttyACM*` device.
The [setup script](../scripts/setup-gpsd.sh) loads that driver when it sees
a u-blox device without a node. That branch also writes a module-load file
for later boots.

## Set up and check

Run these commands from the repository root:

```sh
bash scripts/setup-gpsd.sh
./bin/chase-gps
```

The script installs `gpsd` if needed and enables its socket through `sudo`.
If hotplug misses an existing receiver node, pass the actual path:

```sh
bash scripts/setup-gpsd.sh /dev/ttyACM0
```

## Troubleshooting

- No device node: check USB enumeration and the script's `cdc_acm` message.
- Error `-71` in the kernel log: try another port, cable or powered hub.
  That error appeared in the failed direct-port tests above.
- Receiver found but no fix: give it a clear view of the sky. A cold fix can
  take minutes; waiting does not fix a missing device node.
- gpsd is off: check `systemctl status gpsd.socket` and the setup output.

Other NMEA receivers may work with gpsd, but this project does not claim
that every USB, Bluetooth or phone-based receiver has been tested.
