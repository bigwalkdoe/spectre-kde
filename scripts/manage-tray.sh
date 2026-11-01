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

current_items() {
    python3 - "$TC" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
m = re.search(r'extraItems",?\s*\n(.*?)\);', s, re.S)
if not m:
    sys.exit(0)
for line in m.group(1).splitlines():
    line = line.strip().rstrip('+').strip().strip('"').rstrip(',')
    if line:
        print(line)
PY
}

# Reorder a list of item ids according to DEFAULT_ITEMS, appending unknowns.
order_items() {
    local present="$1"
    local ordered=()
    for d in "${DEFAULT_ITEMS[@]}"; do
        if printf '%s\n' "$present" | grep -qxF "$d"; then
            ordered+=("$d")
        fi
    done
    # append any items not in defaults
    while IFS= read -r it; do
        [ -z "$it" ] && continue
        local found=0
        for d in "${DEFAULT_ITEMS[@]}"; do
            [ "$it" = "$d" ] && { found=1; break; }
        done
        if [ "$found" -eq 0 ]; then
            ordered+=("$it")
        fi
    done <<< "$present"
    printf '%s\n' "${ordered[@]}"
}

pin_tray() {
    local item="$1"
    case "$item" in
        org.kde.plasma.*) ;;
        *) item="org.kde.plasma.$item" ;;
    esac
    local items
    items="$(current_items)"
    if printf '%s\n' "$items" | grep -qxF "$item"; then
        echo -e "${BLUE}Already pinned:${NC} $item"
        return 0
    fi
    local newset
    newset="$(printf '%s\n' "$items"; printf '%s\n' "$item")"
    local ordered
    ordered="$(order_items "$newset")"
    # shellcheck disable=SC2046  # intentional word splitting on item ids
    write_tray_config $(printf '%s\n' "$ordered")
    echo -e "${GREEN}Pinned:${NC} $item"
    echo -e "${BLUE}Run './apply.sh' or './quick-update.sh' to apply${NC}"
}

unpin_tray() {
    local item="$1"
    case "$item" in
        org.kde.plasma.*) ;;
        *) item="org.kde.plasma.$item" ;;
    esac
    local items
    items="$(current_items)"
    if ! printf '%s\n' "$items" | grep -qxF "$item"; then
        echo -e "${RED}Not pinned:${NC} $item"
        return 1
    fi
    local newset
    newset="$(printf '%s\n' "$items" | grep -vxF "$item")"
    local ordered
    ordered="$(order_items "$newset")"
    # shellcheck disable=SC2046  # intentional word splitting on item ids
    write_tray_config $(printf '%s\n' "$ordered")
    echo -e "${GREEN}Unpinned:${NC} $item"
    echo -e "${BLUE}Run './apply.sh' or './quick-update.sh' to apply${NC}"
}

reset_tray() {
    write_tray_config "${DEFAULT_ITEMS[@]}"
    echo -e "${GREEN}Reset tray pinned items to defaults${NC}"
    echo -e "${BLUE}Run './apply.sh' or './quick-update.sh' to apply${NC}"
}

case "${1:-list}" in
    list|ls) list_tray ;;
    status|st) status_tray ;;
    pin|add)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide an item id"
            echo "Usage: $0 pin <item>"
            exit 1
        fi
        pin_tray "$2"
        ;;
    unpin|remove|rm)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide an item id"
            echo "Usage: $0 unpin <item>"
            exit 1
        fi
        unpin_tray "$2"
        ;;
    reset) reset_tray ;;
    *)
        echo -e "${BLUE}spectre-kde Tray Manager${NC}"
        echo "========================"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls          - List pinned tray items"
        echo "  status, st        - Show tray config status"
        echo "  pin <item>        - Pin a tray item"
        echo "  unpin <item>      - Unpin a tray item"
        echo "  reset             - Restore default pinned tray items"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 pin clipboard"
        echo "  $0 unpin battery"
        echo "  $0 reset"
        echo ""
        exit 0
        ;;
esac