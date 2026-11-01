#!/usr/bin/env bash
# spectre-kde -- scripts/manage-tray.sh
# Manage which status items are pinned in the top-bar system tray
# Usage: ./scripts/manage-tray.sh [list|reset|status]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/scripts/tray-config.js"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

DEFAULT_ITEMS=(
    "org.kde.plasma.clipboard"
    "org.kde.plasma.networkmanagement"
    "org.kde.plasma.bluetooth"
    "org.kde.plasma.volume"
    "org.kde.plasma.brightness"
    "org.kde.plasma.battery"
    "org.kde.plasma.notifications"
)

write_tray_config() {
    # $1.. are the item ids
    local items=("$@")
    {
        echo '// spectre-kde — system tray curation (Plasma 6 scripting API)'
        echo '//'
        echo '// Curates which status items are pinned in the top-bar system tray, in order.'
        echo ''
        echo 'var log = [];'
        echo 'var tray = null;'
        echo ''
        echo 'var ids = panelIds.slice();'
        echo 'for (var i = 0; i < ids.length; i++) {'
        echo '    var p = panelById(ids[i]);'
        echo '    if (!p) continue;'
        echo '    var wids = p.widgetIds;'
        echo '    for (var w = 0; w < wids.length; w++) {'
        echo '        var wid = p.widgetById(wids[w]);'
        echo '        if (wid && wid.type === "org.kde.plasma.systemtray") {'
        echo '            tray = wid;'
        echo '        }'
        echo '    }'
        echo '}'
        echo ''
        echo 'if (!tray) {'
        echo '    log.push("ERROR systemtray not found in any panel");'
        echo '} else {'
        echo '    tray.currentConfigGroup = ["General"];'
        echo '    try {'
        echo '        tray.writeConfig('
        echo '            "extraItems",'
        local n=${#items[@]}
        local i=0
        for it in "${items[@]}"; do
            i=$((i+1))
            local comma=""
            if [ "$i" -lt "$n" ]; then comma=","; fi
            local plus=""
            if [ "$i" -lt "$n" ]; then plus=" +"; fi
            echo "            \"$it$comma\"$plus"
        done
        echo '        );'
        echo '        log.push("systemtray curated");'
        echo '    } catch (e) {'
        echo '        log.push("WARN tray curation failed (non-fatal): " + e);'
        echo '    }'
        echo '}'
        echo ''
        echo 'print(log.join("|"));'
    } > "$TC"
}

list_tray() {
    echo -e "${BLUE}Pinned tray items (from scripts/tray-config.js):${NC}"
    echo "=========================================="
    python3 - "$TC" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
m = re.search(r'extraItems",?\s*\n(.*?)\);', s, re.S)
if not m:
    print("  (could not parse extraItems)")
    sys.exit(0)
for line in m.group(1).splitlines():
    line = line.strip().rstrip('+').strip().strip('"').rstrip(',')
    if line:
        print("  " + line)
PY
    echo "=========================================="
    echo -e "\n${BLUE}Run './apply.sh' or './quick-update.sh' to apply changes${NC}"
}

status_tray() {
    echo -e "${BLUE}Tray configuration:${NC}"
    echo "==================="
    if [ -f "$TC" ]; then
        echo -e "${GREEN}Config:${NC} $TC exists"
    else
        echo -e "${RED}Missing:${NC} $TC"
    fi
    echo "==================="
}

reset_tray() {
    write_tray_config "${DEFAULT_ITEMS[@]}"
    echo -e "${GREEN}Reset tray pinned items to defaults${NC}"
    echo -e "${BLUE}Run './apply.sh' or './quick-update.sh' to apply${NC}"
}

case "${1:-list}" in
    list|ls) list_tray ;;
    status|st) status_tray ;;
    reset) reset_tray ;;
    *)
        echo -e "${BLUE}spectre-kde Tray Manager${NC}"
        echo "========================"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  list, ls     - List pinned tray items"
        echo "  status, st   - Show tray config status"
        echo "  reset        - Restore default pinned tray items"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 reset"
        echo ""
        exit 0
        ;;
esac