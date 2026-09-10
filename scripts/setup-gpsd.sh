#!/usr/bin/env bash
# Own the one GPS source: install gpsd if missing, enable its socket, and
# wait for the receiver to show up in `chase-gps status`. Usage:
#   bash scripts/setup-gpsd.sh [device]
# Without a device argument it relies on gpsd's USB hotplug (what a VK-162
# needs); pass one (e.g. /dev/ttyUSB0) to attach it explicitly when hotplug
# misses. Needs sudo for the install and the service.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { printf '%s\n' "$@" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ -f bin/chase-gps ]] || die "Run from the repository root: bin/chase-gps missing."
export PATH="$PWD/bin:$PATH"

if ! pacman -Q gpsd >/dev/null 2>&1; then
  echo "Installing gpsd (sudo)…"
  sudo pacman -S --needed --noconfirm gpsd || die "gpsd install failed."
fi

# A u-blox puck is a CDC-ACM device. Arch does not always autoload that
# module, and without it the receiver enumerates on the USB bus with no
# interfaces and no /dev/ttyACM node — the failure looks like a dead
# receiver. Load it and make the load persist across reboots.
if ! compgen -G '/dev/ttyACM*' > /dev/null && lsusb 2>/dev/null | grep -qi 'u-blox'; then
  echo "u-blox receiver present with no /dev/ttyACM — loading cdc_acm (sudo)…"
  sudo modprobe cdc_acm || die "Could not load cdc_acm."
  printf 'cdc_acm\n' | sudo tee /etc/modules-load.d/omarchy-chase-gps.conf > /dev/null
  for _ in {1..10}; do compgen -G '/dev/ttyACM*' > /dev/null && break; sleep 0.5; done
  if ! compgen -G '/dev/ttyACM*' > /dev/null; then
    # -71 (EPROTO) on the config set is electrical, not driver: a flaky
    # cable, an underpowered or fussy xHCI port. Say so, because "reseat
    # the receiver" sends people hunting for a software fix that does not
    # exist.
    if journalctl -k -S -30min --no-pager 2>/dev/null | grep -qE "usb .*(can't set config|device descriptor read).*(-71|error)"; then
      die "The receiver enumerates but the port cannot configure it (kernel error -71)." \
        "That is a cable or port fault, not a driver one. In order:" \
        "  1. Move it to a different USB port (a USB-2 port, or through a powered hub)." \
        "  2. Use the USB extension cable rather than the bare plug." \
        "  3. Re-run this script; check with: journalctl -k -g 'usb 1-' | tail"
    fi
    die "cdc_acm is loaded but no /dev/ttyACM appeared. Reseat the receiver and re-run."
  fi
fi

echo "Enabling gpsd.socket (sudo)…"
sudo systemctl enable --now gpsd.socket || die "Could not enable gpsd.socket."

if [[ -n ${1:-} ]]; then
  [[ -e $1 ]] || die "No such device: $1 (plug the receiver in first)."
  echo "Attaching $1 (sudo)…"
  sudo gpsdctl add "$1" || die "gpsdctl refused $1."
fi

echo "Waiting up to 30 s for the receiver…"
for _ in {1..30}; do
  out=$(chase-gps) && { echo "$out"; exit 0; }
  [[ $out == *"no device"* || $out == *"off"* ]] || { echo "$out"; exit 0; }
  sleep 1
done
die "$(chase-gps): still nothing after 30 s. Reseat the receiver where it sees sky and re-run."
