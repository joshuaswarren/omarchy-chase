#!/usr/bin/env bash
# Fetch the pinned HookEcho AppImage, verify its committed sha256, and wire
# it into the desktop: the AppImage under
# $XDG_DATA_HOME/omarchy-chase/bin, `hookecho` on PATH through
# ~/.local/bin, and a .desktop entry registering x-scheme-handler/hookecho
# (in the shape of Omastorm's scripts/install-engine.sh and
# scripts/install-launcher.sh). `--remove` undoes all three.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { printf '%s\n' "$@" >&2; exit 1; }

case ${1:-} in
  ''|--print-path|--remove) ;;
  *) die "usage: install-hookecho.sh [--print-path] [--remove]" ;;
esac

pin_file=${HOOKECHO_PIN:-hookecho.release.pin}
[[ -f $pin_file ]] || die "HookEcho pin missing: $pin_file"
tag= repo= asset= sha256=
while IFS= read -r line || [[ -n $line ]]; do
  [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
  key=${line%%=*}
  val=${line#*=}
  case $key in
    tag|repo|asset|sha256) printf -v "$key" '%s' "$val" ;;
    *) die "Unknown key in $pin_file: $key" ;;
  esac
done < "$pin_file"
[[ -n $tag && -n $repo && -n $asset && -n $sha256 ]] || die "Incomplete pin in $pin_file"
[[ $sha256 =~ ^[a-f0-9]{64}$ ]] || die "Pin sha256 in $pin_file is not 64 lowercase hex digits"

machine=${HOOKECHO_MACHINE:-$(uname -m)}
[[ $machine == x86_64 ]] || die "No $machine HookEcho asset pinned (only the x86_64 AppImage)."

data_home=${XDG_DATA_HOME:-$HOME/.local/share}
bin_dir=$data_home/omarchy-chase/bin
app=$bin_dir/$asset
link=$HOME/.local/bin/hookecho
desktop=$data_home/applications/hookecho.desktop

hash_of() { sha256sum -- "$1" | awk '{print $1}'; }
refresh_dbs() {
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$data_home/applications" >/dev/null 2>&1 || true
}

if [[ ${1:-} == --remove ]]; then
  rm -f -- "$link" "$desktop" "$app"
  refresh_dbs
  echo "HookEcho removed (empty directories under $bin_dir left alone)."
  exit 0
fi

if [[ -x $app ]] && [[ $(hash_of "$app") == "$sha256" ]]; then
  : # already installed and intact
else
  work=$(mktemp -d "${TMPDIR:-/tmp}/hookecho-install.XXXXXX")
  trap 'rm -rf "$work"' EXIT
  tmp=$work/$asset
  if [[ -n ${HOOKECHO_ASSET:-} ]]; then
    [[ -f $HOOKECHO_ASSET ]] || die "HOOKECHO_ASSET is not a file: $HOOKECHO_ASSET"
    cp -- "$HOOKECHO_ASSET" "$tmp"
  else
    url=${HOOKECHO_URL:-https://github.com/$repo/releases/download/$tag/$asset}
    curl -fsSL --retry 2 -A "omarchy-chase (https://github.com/joshuaswarren/omarchy-chase)" -o "$tmp" -- "$url" \
      || die "Could not download $asset from $url."
  fi
  got=$(hash_of "$tmp")
  [[ $got == "$sha256" ]] || die "HookEcho sha256 mismatch for $asset." "expected $sha256" "got      $got"
  mkdir -p -- "$bin_dir"
  chmod 755 -- "$tmp"
  mv -f -- "$tmp" "$app"
  trap - EXIT
fi

mkdir -p -- "$HOME/.local/bin" "$data_home/applications"
ln -sf -- "$app" "$link"
tmpd=$(mktemp -- "$data_home/applications/hookecho.desktop.XXXXXX")
trap 'rm -f -- "$tmpd"' EXIT
cat > "$tmpd" <<EOF
[Desktop Entry]
Type=Application
Name=HookEcho
GenericName=Weather radar
Comment=Full NEXRAD viewer for storm chasing
Exec=$app %u
TryExec=$app
MimeType=x-scheme-handler/hookecho;
Terminal=false
StartupNotify=false
Categories=Science;
Keywords=radar;NEXRAD;weather;chase;
EOF
chmod 644 -- "$tmpd"
mv -f -- "$tmpd" "$desktop"
trap - EXIT
refresh_dbs

[[ ${1:-} == --print-path ]] && printf '%s\n' "$app"
echo "HookEcho $tag installed: $app"
exit 0
