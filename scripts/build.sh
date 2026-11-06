#!/usr/bin/env bash
# Build one notification app per runtime into <dest>. Icons come from what is
# installed on this Mac, so no third-party logo lives in this repository.
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

# Turn a white vector logo into an .icns on the macOS icon grid.
glyph_icon() {
  local glyph=$1 out=$2 set=$work/icon.iconset size
  mkdir -p "$set"
  "$work/make-icon" "$glyph" "$work/icon.png"
  for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" "$work/icon.png" --out "$set/icon_${size}x${size}.png" >/dev/null
    sips -s format png -z $((size * 2)) $((size * 2)) "$work/icon.png" --out "$set/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$out"
}

bundle() {
  local key=$1 name=$2 icns=$3 glyph=$4
  local app=$dest/$name.app
  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$work/suzu" "$app/Contents/MacOS/suzu"
  if [[ -n $icns ]]; then
    cp "$icns" "$app/Contents/Resources/AppIcon.icns"
  elif [[ -n $glyph ]]; then
    glyph_icon "$glyph" "$app/Contents/Resources/AppIcon.icns"
  else
    echo "suzu: no $name icon found on this Mac; it will show a blank icon" >&2
  fi
  sed -e "s/@KEY@/$key/" -e "s/@NAME@/$name/" "$root/scripts/Info.plist.in" >"$app/Contents/Info.plist"
  codesign --force --sign - "$app"
}

bundle claude "Claude Code" "$(app_icon /Applications/Claude.app || true)" ""
bundle codex "Codex" "$(app_icon /Applications/Codex.app || true)" \
  "$(extension_file openai.chatgpt resources/blossom-white.svg || true)"
