# Roadmap

## Available now

- Install and remove the pinned HookEcho AppImage, with a checksum check and
  a desktop URL handler.
- Set up a shared `gpsd` receiver, inspect its fix, and bridge NMEA data to
  Supercell Wx.
- Start and stop a chase session from the bar panel. Show GPS, network,
  metered-connection and viewer status.
- Open the view exported by Omastorm in HookEcho through `bin/chase-open`.

See the [README](README.md) for setup and the
[GPS receiver guide](docs/gps-receivers.md) for USB troubleshooting.

## Next work

- Check both viewers on a moving GPS feed, including receiver disconnection.
- Check the full session from a cold desktop through Start and Stop.
- Expose connection changes to viewers and improve recovery after coverage
  gaps. Weather-data fetching and download policy belong in the viewer.
- Evaluate fuller Supercell Wx integration when a chase workflow needs it.
  The NMEA setup alone is not a complete second-viewer integration.

This project does not decode radar or run a shared weather-data service.
It connects existing viewers to the Omarchy desktop.

## Related upstream work

These changes explain the integration choices:

- [Omastorm #17](https://github.com/wesleygrimes/omastorm/pull/17): the original
  viewer-specific control proposal. The later design exports the view for a
  desktop action instead.
- [Omastorm #52](https://github.com/wesleygrimes/omastorm/pull/52): the view
  export consumed by `bin/chase-open`.
- [HookEcho #315](https://github.com/d4vid87/hookecho/pull/315): Arch packaging.
- [HookEcho #322](https://github.com/d4vid87/hookecho/pull/322): GPS connection
  at launch.
- [Omastorm #51](https://github.com/wesleygrimes/omastorm/pull/51): GPS following.
