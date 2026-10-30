#!/usr/bin/env bash
# spectre-kde -- scripts/clean-plasmashellrc.sh
# Remove stale [PlasmaViews][Panel N] sections from plasmashellrc for panels
# that no longer exist in plasma-org.kde.plasma.desktop-appletsrc.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RC="$HOME/.config/plasmashellrc"
APP="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
[ -f "$RC" ] || exit 0
[ -f "$APP" ] || exit 0

PANELS="$(awk '/^\[Containments\]\[[0-9]+\]/{id=$0; gsub(/[^0-9]/,"",id)} /plugin=org.kde.panel/{print id}' "$APP" | sort -u)"
[ -z "$PANELS" ] && exit 0

python3 - "$RC" "$PANELS" <<'PY'
import re, sys
rc, panels = sys.argv[1], set(sys.argv[2].split())
lines = open(rc).read().splitlines(keepends=True)
out = []
keep = True
current_panel = None
section_re = re.compile(r'^\[PlasmaViews\]\[Panel (\d+)\]')
defaults_re = re.compile(r'^\[PlasmaViews\]\[Panel (\d+)\]\[Defaults\]')
for line in lines:
    s = line.strip()
    m = section_re.match(s)
    dm = defaults_re.match(s)
    if m:
        current_panel = m.group(1)
        keep = current_panel in panels
    elif dm:
        keep = dm.group(1) in panels
    elif s.startswith('['):
        # any other section header (e.g. [Updates]) - always keep
        keep = True
        current_panel = None
    if keep:
        out.append(line)
open(rc, 'w').write(''.join(out))
PY
echo "cleaned plasmashellrc (kept panels: $(echo "$PANELS" | tr '\n' ' '))"
chmod +x /home/deon/dev/github/spectre-kde/scripts/clean-plasmashellrc.sh 2>/dev/null
