#!/usr/bin/env bash
# spectre-kde -- scripts/manage-topbar.sh
# Manage top bar (menu bar) widget visibility and appearance
# Usage: ./scripts/manage-topbar.sh [list|status|toggle <item>|set <key> <value>|reset]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/scripts/topbar-config"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
DEFAULTS=(
    "TOPBAR_HEIGHT_MULTIPLIER=10/6"
    "TOPBAR_SHOW_APP_MENU=true"
    "TOPBAR_SHOW_PAGER=true"
    "TOPBAR_SHOW_NETSPEED=true"
    "TOPBAR_SHOW_TRAY=true"
    "TOPBAR_SHOW_CLOCK=true"
)

get_val() {
    local key="$1"
    if [ -f "$CFG" ]; then
        grep -E "^${key}=" "$CFG" 2>/dev/null | tail -1 | cut -d= -f2-
    fi
}

set_val() {
    local key="$1" val="$2"
    if [ ! -f "$CFG" ]; then
        printf '%s\n' "${DEFAULTS[@]}" > "$CFG"
    fi
    if grep -qE "^${key}=" "$CFG"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$CFG"
    else
        echo "${key}=${val}" >> "$CFG"
    fi
}

list_topbar() {
    echo -e "${BLUE}Top bar configuration (scripts/topbar-config):${NC}"
    echo "=========================================="
    if [ -f "$CFG" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            echo "  $line"
        done < "$CFG"
    else
        echo "  (no config file; defaults will be used)"
    fi
    echo "=========================================="
    echo -e "\n${BLUE}Run './apply.sh' or './quick-update.sh' to apply${NC}"
}

status_topbar() {
    echo -e "${BLUE}Top bar status:${NC}"
    for k in TOPBAR_HEIGHT_MULTIPLIER TOPBAR_SHOW_APP_MENU TOPBAR_SHOW_PAGER TOPBAR_SHOW_NETSPEED TOPBAR_SHOW_TRAY TOPBAR_SHOW_CLOCK; do
        echo "  $k = $(get_val "$k")"
    done
}

toggle_topbar() {
    local item="$1"
    local key=""
    case "$item" in
        appmenu|app-menu|menu) key="TOPBAR_SHOW_APP_MENU" ;;
        pager) key="TOPBAR_SHOW_PAGER" ;;
        netspeed|net-speed|network-speed) key="TOPBAR_SHOW_NETSPEED" ;;
        tray) key="TOPBAR_SHOW_TRAY" ;;
        clock) key="TOPBAR_SHOW_CLOCK" ;;
        *) echo -e "${RED}Unknown item: $item${NC} (appmenu|pager|netspeed|tray|clock)"; return 1 ;;
    esac
    local cur
    cur="$(get_val "$key")"
    if [ "$cur" = "true" ]; then
        set_val "$key" "false"
        echo -e "${GREEN}Disabled:${NC} $item (TOPBAR_SHOW_* = false)"
    else
        set_val "$key" "true"
        echo -e "${GREEN}Enabled:${NC} $item (TOPBAR_SHOW_* = true)"
    fi
    echo -e "${BLUE}Run './quick-update.sh' to apply${NC}"
}

reset_topbar() {
    printf '%s\n' "${DEFAULTS[@]}" > "$CFG"
    # preserve header comments? rewrite with header
    {
        echo "# spectre-kde top bar configuration"
        echo "# Customize top bar appearance and widgets"
        echo ""
        echo "# Top bar height multiplier (grid units)"
        echo "TOPBAR_HEIGHT_MULTIPLIER=10/6"
        echo ""
        echo "# Show global menu (true/false)"
        echo "TOPBAR_SHOW_APP_MENU=true"
        echo ""
        echo "# Show workspace pager (true/false)"
        echo "TOPBAR_SHOW_PAGER=true"
        echo ""
        echo "# Show network speed widget (true/false)"
        echo "TOPBAR_SHOW_NETSPEED=true"
        echo ""
        echo "# Show system tray (true/false)"
        echo "TOPBAR_SHOW_TRAY=true"
        echo ""
        echo "# Show digital clock (true/false)"
        echo "TOPBAR_SHOW_CLOCK=true"
    } > "$CFG"
    echo -e "${GREEN}Reset top bar to defaults${NC}"
    echo -e "${BLUE}Run './quick-update.sh' to apply${NC}"
}

case "${1:-list}" in
    list|ls) list_topbar ;;
    status|st) status_topbar ;;
    toggle)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} provide an item (appmenu|pager|tray|clock)"
            exit 1
        fi
        toggle_topbar "$2"
        ;;
    set)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo -e "${RED}Error:${NC} usage: $0 set <key> <value>"
            exit 1
        fi
        set_val "$2" "$3"
        echo -e "${GREEN}Set ${2}=${3}${NC}"
        ;;
    reset) reset_topbar ;;
    *)
        echo -e "${BLUE}spectre-kde Top Bar Manager${NC}"
        echo "==========================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls          - Show top bar config"
        echo "  status, st        - Show current values"
        echo "  toggle <item>     - Toggle appmenu|pager|netspeed|tray|clock"
        echo "  set <key> <val>   - Set a config key"
        echo "  reset             - Restore defaults"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 toggle netspeed"
        echo "  $0 set TOPBAR_HEIGHT_MULTIPLIER 12/6"
        echo "  $0 reset"
        echo ""
        exit 0
        ;;
esac