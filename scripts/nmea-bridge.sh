#!/usr/bin/env bash
# Serve gpsd's NMEA as TCP for Supercell Wx: start | stop | status.
# HookEcho needs nothing — its "Connect GPS (gpsd)" button reads the daemon
# on :2947 directly. Supercell Wx takes an NMEA network source instead, so
# point its GPS Plugin at: socket://127.0.0.1:2948
# (File > Settings > General > GPS Plugin > NMEA > network source).
set -euo pipefail

port=${CHASE_NMEA_PORT:-2948}
run_dir=${XDG_RUNTIME_DIR:-/tmp}/omarchy-chase
pidfile=$run_dir/nmea-bridge.pid

die() { printf '%s\n' "$@" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

case ${1:-status} in
  start)
    have gpspipe || die "gpspipe missing (pacman -S gpsd)."
    have socat || die "socat missing (pacman -S socat)."
    gpspipe -w -n 1 127.0.0.1 >/dev/null 2>&1 || die "gpsd not answering on :2947 — run scripts/setup-gpsd.sh first."
    mkdir -p -- "$run_dir"
    if [[ -f $pidfile ]] && kill -0 "$(cat -- "$pidfile")" 2>/dev/null; then
      die "Bridge already running (pid $(cat -- "$pidfile"))."
    fi
    setsid -f bash -c 'exec gpspipe -r 127.0.0.1 2>/dev/null | exec socat - TCP-LISTEN:"$0",bind=127.0.0.1,fork,reuseaddr' "$port" >/dev/null 2>&1
    for _ in {1..20}; do
      pid=$(pgrep -f "TCP-LISTEN:$port" | head -n 1) && [[ -n $pid ]] && { echo "$pid" > "$pidfile"; echo "NMEA bridge on 127.0.0.1:$port (pid $pid)."; exit 0; }
      sleep 0.25
    done
    die "Bridge did not come up on :$port."
    ;;
  stop)
    [[ -f $pidfile ]] || die "No bridge pidfile ($pidfile)."
    kill "$(cat -- "$pidfile")" 2>/dev/null || true
    rm -f -- "$pidfile"
    echo "Bridge stopped."
    ;;
  status)
    if [[ -f $pidfile ]] && kill -0 "$(cat -- "$pidfile")" 2>/dev/null; then
      echo "Bridge up on 127.0.0.1:$port (pid $(cat -- "$pidfile"))."
    else
      echo "Bridge down."
      exit 1
    fi
    ;;
  *) die "usage: nmea-bridge.sh [start|stop|status]" ;;
esac
