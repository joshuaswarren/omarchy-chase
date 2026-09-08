#!/usr/bin/env bash
# One chase session: start | stop | status. Start brings up the NMEA bridge
# and the viewer; stop takes both down. GPS itself is owned by gpsd (see
# scripts/setup-gpsd.sh), not by the session — a session without a fix is
# still a working viewer, it just doesn't follow you.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { printf '%s\n' "$@" >&2; exit 1; }

viewer_running() { pgrep -x hookecho >/dev/null 2>&1; }
bridge_running() { bash scripts/nmea-bridge.sh status >/dev/null 2>&1; }

case ${1:-status} in
  start)
    if ! bridge_running; then
      bash scripts/nmea-bridge.sh start || die "NMEA bridge failed to start."
    fi
    if ! viewer_running; then
      command -v hookecho >/dev/null 2>&1 || die "hookecho not on PATH — run scripts/install-hookecho.sh first."
      setsid -f hookecho >/dev/null 2>&1 || die "HookEcho failed to launch."
      for _ in {1..20}; do viewer_running && break; sleep 0.5; done
      viewer_running || die "HookEcho did not appear."
    fi
    echo "Session active: viewer + NMEA bridge."
    ;;
  stop)
    bash scripts/nmea-bridge.sh stop >/dev/null 2>&1 || true
    if viewer_running; then
      pkill -x hookecho || die "Could not stop HookEcho."
    fi
    echo "Session stopped."
    ;;
  status)
    if viewer_running || bridge_running; then
      echo "active"
    else
      echo "idle"
      exit 1
    fi
    ;;
  *) die "usage: chase-session.sh [start|stop|status]" ;;
esac
