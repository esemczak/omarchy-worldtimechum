#!/usr/bin/env bash
set -euo pipefail
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
omarchy plugin validate "$PWD"
destination="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/local.worldtimechum"
mkdir -p "$destination"
for file in manifest.json BarWidget.qml TimePanel.qml ChumText.qml timezones.py; do
  install -m 644 "$file" "$destination/$file"
done
omarchy-shell shell rescanPlugins
omarchy plugin enable local.worldtimechum
omarchy bar put local.worldtimechum --section right
