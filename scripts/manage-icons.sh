#!/usr/bin/env bash
# spectre-kde -- scripts/manage-icons.sh
# Manage icon theme
# Usage: ./scripts/manage-icons.sh [status|set <theme>|fairywren]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

status_icons() {
    echo -e "${BLUE}Icon Theme Status:${NC}"
    echo "========================================"
    if [ -f "$HOME/.config/kdeglobals" ]; then
        theme="$(grep -A5 '\[Icons\]' "$HOME/.config/kdeglobals" 2>/dev/null | grep 'Theme' | cut -d= -f2 || echo '(unset)')"
        echo -e "${GREEN}Theme:${NC} ${theme:-unset}"
    fi
    echo "========================================"
}

set_icons() {
    local theme="$1"
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$theme" 2>/dev/null || true
    # Update GTK
    for g in gtk-3.0 gtk-4.0; do
        mkdir -p "$HOME/.config/$g"
        if [ -f "$HOME/.config/$g/settings.ini" ]; then
            if grep -q '^gtk-icon-theme-name=' "$HOME/.config/$g/settings.ini"; then
                sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$theme/" "$HOME/.config/$g/settings.ini"
            else
                echo "gtk-icon-theme-name=$theme" >> "$HOME/.config/$g/settings.ini"
            fi
        fi
    done
    echo -e "${GREEN}Icon theme set to:${NC} $theme"
}

case "${1:-status}" in
    status|st) status_icons ;;
    set)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} provide a theme name"
            exit 1
        fi
        set_icons "$2"
        ;;
    fairywren)
        set_icons "FairyWren_Light"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Icon Manager${NC}"
        echo "========================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status, st   - Show current icon theme"
        echo "  set <theme>  - Set icon theme"
        echo "  fairywren    - Set to FairyWren_Light"
        echo ""
        exit 0
        ;;
esac
