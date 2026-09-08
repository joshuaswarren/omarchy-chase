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
