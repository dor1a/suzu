#!/usr/bin/env bash
# Build one notification app per sender into <dest>. The Claude Code and Codex
# icons come from what is installed on this Mac, so no third-party logo lives in
# this repository. The suzu app uses suzu's own logo.
#
# Usage: scripts/build.sh <dest>
# SUZU_HOME overrides the home searched for icons; Homebrew replaces HOME while building.
set -euo pipefail

dest=${1:?usage: scripts/build.sh <dest>}
root=$(cd "$(dirname "$0")/.." && pwd)
home=${SUZU_HOME:-$HOME}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

swiftc -O -o "$work/suzu" "$root/Sources/main.swift"
swiftc -O -o "$work/make-icon" "$root/scripts/make-icon.swift"

app_icon() {
  local app=$1 file
  [[ -d $app ]] || return 1
  file=$(/usr/bin/defaults read "$app/Contents/Info" CFBundleIconFile 2>/dev/null) || return 1
  file=$app/Contents/Resources/${file%.icns}.icns
  [[ -f $file ]] && printf '%s\n' "$file"
}

# Newest copy of a VS Code extension resource.
extension_file() {
  local found
  found=$(ls -d "$home"/.vscode/extensions/"$1"-* 2>/dev/null | sort -V | tail -1)
  [[ -n $found && -f $found/$2 ]] && printf '%s\n' "$found/$2"
}

# Turn a vector logo into an .icns on the macOS icon grid.
# Usage: grid_icon <out.icns> [--full] <logo.svg>
grid_icon() {
  local out=$1 set=$work/icon.iconset size
  shift
  mkdir -p "$set"
  "$work/make-icon" "$@" "$work/icon.png"
  for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" "$work/icon.png" --out "$set/icon_${size}x${size}.png" >/dev/null
    sips -s format png -z $((size * 2)) $((size * 2)) "$work/icon.png" --out "$set/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$out"
}

# Usage: bundle <key> <name> <icns> <white glyph> [full-color logo]
bundle() {
  local key=$1 name=$2 icns=$3 glyph=$4 logo=${5:-}
  local app=$dest/$name.app
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$work/suzu" "$app/Contents/MacOS/suzu"
  if [[ -n $icns ]]; then
    cp "$icns" "$app/Contents/Resources/AppIcon.icns"
  elif [[ -n $glyph ]]; then
    grid_icon "$app/Contents/Resources/AppIcon.icns" "$glyph"
  elif [[ -n $logo ]]; then
    grid_icon "$app/Contents/Resources/AppIcon.icns" --full "$logo"
  else
    echo "suzu: no $name icon found on this Mac; it will show a blank icon" >&2
  fi
  sed -e "s/@KEY@/$key/" -e "s/@NAME@/$name/" "$root/scripts/Info.plist.in" >"$app/Contents/Info.plist"
  codesign --force --sign - "$app"
}

bundle claude "Claude Code" "$(app_icon /Applications/Claude.app || true)" ""
bundle codex "Codex" "$(app_icon /Applications/Codex.app || true)" \
  "$(extension_file openai.chatgpt resources/blossom-white.svg || true)"
bundle suzu "suzu" "" "" "$root/docs/logo.svg"
