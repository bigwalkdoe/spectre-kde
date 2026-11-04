#!/usr/bin/env bash
# spectre-kde -- scripts/manage-cursor.sh
# Manage cursor theme settings
# Usage: ./scripts/manage-cursor.sh [status|set <theme>|bibata]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

status_cursor() {
    echo -e "${BLUE}Cursor Theme Status:${NC}"
    echo "========================================"
    if [ -f "$HOME/.config/kcminputrc" ]; then
        theme="$(grep -A2 '\[Mouse\]' "$HOME/.config/kcminputrc" 2>/dev/null | grep 'cursorTheme' | cut -d= -f2 || echo '(unset)')"
        size="$(grep -A2 '\[Mouse\]' "$HOME/.config/kcminputrc" 2>/dev/null | grep 'cursorSize' | cut -d= -f2 || echo '(unset)')"
        echo -e "${GREEN}Theme:${NC} ${theme:-unset}"
        echo -e "${GREEN}Size:${NC} ${size:-unset}"
    else
        echo -e "${RED}kcminputrc not configured${NC}"
    fi
    echo "========================================"
}

set_cursor() {
    local theme="$1"
    local size="${2:-24}"
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$theme" 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$size" 2>/dev/null || true
    # Also update GTK
    for g in gtk-3.0 gtk-4.0; do
        mkdir -p "$HOME/.config/$g"
        if [ -f "$HOME/.config/$g/settings.ini" ]; then
            if grep -q '^gtk-cursor-theme-name=' "$HOME/.config/$g/settings.ini"; then
                sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$theme/" "$HOME/.config/$g/settings.ini"
            else
                echo "gtk-cursor-theme-name=$theme" >> "$HOME/.config/$g/settings.ini"
            fi
            if grep -q '^gtk-cursor-theme-size=' "$HOME/.config/$g/settings.ini"; then
                sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$size/" "$HOME/.config/$g/settings.ini"
            else
                echo "gtk-cursor-theme-size=$size" >> "$HOME/.config/$g/settings.ini"
            fi
        fi
    done
    echo -e "${GREEN}Cursor theme set to:${NC} $theme (size: $size)"
}

case "${1:-status}" in
    status|st) status_cursor ;;
    set)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} provide a theme name"
            echo "Usage: $0 set <theme> [size]"
            exit 1
        fi
        set_cursor "$2" "${3:-24}"
        ;;
    bibata)
        set_cursor "Bibata-Modern-Ice" "24"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Cursor Manager${NC}"
        echo "============================"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  status, st      - Show current cursor theme"
        echo "  set <theme> [size] - Set cursor theme"
        echo "  bibata          - Set to Bibata-Modern-Ice"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 set Bibata-Modern-Ice"
        echo ""
        exit 0
        ;;
esac
