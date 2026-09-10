#!/usr/bin/env bash
# Point Supercell Wx at the NMEA bridge, without the settings dialog. Its
# general settings are plain JSON; the positioning plugin takes the
# lower-cased enum name ("nmea") and the source takes the Qt NMEA plugin's
# socket:// form (scwx-qt/source/scwx/qt/settings/general_settings.cpp,
# manager/position_manager.cpp). Run with Supercell Wx closed: it rewrites
# the file on exit and would overwrite this.
set -euo pipefail

port=${CHASE_NMEA_PORT:-2948}
settings=${SCWX_SETTINGS:-$HOME/.local/share/Supercell Wx/settings.json}

die() { printf '%s\n' "$@" >&2; exit 1; }

pgrep -f 'supercell-wx' >/dev/null 2>&1 && die "Close Supercell Wx first: it rewrites settings.json on exit."
[[ -f $settings ]] || die "No Supercell Wx settings at $settings (launch it once and close it)."

python3 - "$settings" "$port" <<'EOF'
import json, sys
path, port = sys.argv[1], sys.argv[2]
with open(path) as f:
    d = json.load(f)
g = d.setdefault("general", {})
before = {k: g.get(k) for k in ("positioning_plugin", "nmea_source", "track_location")}
g["positioning_plugin"] = "nmea"
g["nmea_source"] = f"socket://127.0.0.1:{port}"
g["track_location"] = True
with open(path, "w") as f:
    json.dump(d, f, indent=4)
    f.write("\n")
print(f"Supercell Wx: GPS plugin NMEA, source socket://127.0.0.1:{port}, track on (was {before})")
EOF
