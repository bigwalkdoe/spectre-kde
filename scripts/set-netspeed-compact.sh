#!/usr/bin/env bash
# spectre-kde -- scripts/set-netspeed-compact.sh
# Post-layout polish for the top-bar network speed widget.
#
# layout.js creates org.kde.plasma.systemmonitor.net with a text-only face
# (numeric up/down). Some compact label/title tweaks are easier to apply via
# targeted appletsrc config after the widget exists than through the scripting
# API string passed to gdbus evaluateScript. This script is best-effort: it
# warns on problems but exits 0 so a cosmetic polish issue never blocks apply.
#
# Usage: set-netspeed-compact.sh "<layout.js output>"
set -u

APPLET_RC="plasma-org.kde.plasma.desktop-appletsrc"
LAYOUT_OUT="${1:-}"

# Read TOPBAR_SHOW_NETSPEED from config if available.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOPBAR_CFG="$ROOT/scripts/topbar-config"
TOPBAR_SHOW_NETSPEED=true
if [ -f "$TOPBAR_CFG" ]; then
  # shellcheck disable=SC1090
  . "$TOPBAR_CFG"
  TOPBAR_SHOW_NETSPEED="${TOPBAR_SHOW_NETSPEED:-true}"
fi
if [ "$TOPBAR_SHOW_NETSPEED" != "true" ]; then
  echo "  netspeed compact: disabled in topbar-config, skipping"
  exit 0
fi

TOP_PANEL="$(printf '%s' "$LAYOUT_OUT" | grep -oE 'panelIds=[0-9]+,[0-9]+' | head -1 | cut -d= -f2 | cut -d, -f1)"
if [ -z "$TOP_PANEL" ]; then
  echo "  netspeed compact: no top panel id in layout output, skipping"
  exit 0
fi

# Find the systemmonitor.net applet under the top panel containment.
APPLET_ID="$(python3 - "$HOME/.config/$APPLET_RC" "$TOP_PANEL" <<'PY'
import re, sys
path, panel = sys.argv[1], sys.argv[2]
try:
    lines = open(path, encoding='utf-8', errors='ignore').read().splitlines()
except OSError:
    sys.exit(0)
pat = re.compile(r'\[Containments\]\[' + re.escape(panel) + r'\]\[Applets\]\[(\d+)\]\s*$')
i = 0
while i < len(lines):
    m = pat.match(lines[i])
    if m:
        aid = m.group(1)
        j = i + 1
        while j < len(lines) and not (lines[j].startswith('[') and f'[Applets][{aid}]' not in lines[j]):
            if lines[j].strip() == 'plugin=org.kde.plasma.systemmonitor.net':
                print(aid)
                sys.exit(0)
            j += 1
        i = j
        continue
    i += 1
PY
)"

if [ -z "$APPLET_ID" ]; then
  echo "  netspeed compact: no systemmonitor.net widget found in top panel $TOP_PANEL, skipping"
  exit 0
fi

BASE=(--file "$APPLET_RC" --group Containments --group "$TOP_PANEL" --group Applets --group "$APPLET_ID" --group Configuration)

# Keep text-only numeric sensors and minimize chrome. sensorLabels are not set
# here: the controller key/format varies and gdbus/kwriteconfig6 handling is
# fragile; the text-only face with download+upload sensors is the reliable core.
kwriteconfig6 "${BASE[@]}" --group Appearance --key chartFace "org.kde.ksysguard.textonly" 2>/dev/null || true
kwriteconfig6 "${BASE[@]}" --group Appearance --key title --delete 2>/dev/null || true
kwriteconfig6 "${BASE[@]}" --group Sensors --key highPrioritySensorIds '["network/all/download","network/all/upload"]' 2>/dev/null || true

echo "  netspeed compact: applied to top panel $TOP_PANEL applet $APPLET_ID"
exit 0
