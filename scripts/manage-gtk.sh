#!/usr/bin/env bash
# spectre-kde -- scripts/manage-gtk.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

status_gtk() {
    echo -e "${BLUE}GTK Theme Status:${NC}"
    echo "========================================"
    for g in gtk-3.0 gtk-4.0; do
        if [ -f "$HOME/.config/$g/settings.ini" ]; then
            theme="$(grep "^gtk-theme-name=" "$HOME/.config/$g/settings.ini" 2>/dev/null | cut -d= -f2 || echo "(unset)")"
            echo -e "${GREEN}$g:${NC} $theme"
        else
            echo -e "${RED}$g:${NC} not configured"
        fi
    done
    echo "========================================"
}

set_gtk_theme() {
    local theme="$1"
    local dark="false"
    case "$theme" in
        *Dark*|*dark*) dark="true" ;;
    esac
    for g in gtk-3.0 gtk-4.0; do
        mkdir -p "$HOME/.config/$g"
        if [ -f "$HOME/.config/$g/settings.ini" ]; then
            if grep -q "^gtk-theme-name=" "$HOME/.config/$g/settings.ini"; then
                sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$HOME/.config/$g/settings.ini"
            else
                echo "gtk-theme-name=$theme" >> "$HOME/.config/$g/settings.ini"
            fi
            if grep -q "^gtk-application-prefer-dark-theme=" "$HOME/.config/$g/settings.ini"; then
                sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark/" "$HOME/.config/$g/settings.ini"
            else
                echo "gtk-application-prefer-dark-theme=$dark" >> "$HOME/.config/$g/settings.ini"
            fi
        else
            { echo "[Settings]"; echo "gtk-theme-name=$theme"; echo "gtk-application-prefer-dark-theme=$dark"; } > "$HOME/.config/$g/settings.ini"
        fi
    done
    echo -e "${GREEN}GTK theme set to:${NC} $theme"
}

case "${1:-status}" in
    status|st) status_gtk ;;
    set)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} provide a theme name"
            echo "Usage: $0 set <theme>"
            exit 1
        fi
        set_gtk_theme "$2"
        ;;
    dark) set_gtk_theme "Orchis-Dark" ;;
    light) set_gtk_theme "Breeze" ;;
    *)
        echo -e "${BLUE}spectre-kde GTK Manager${NC}"
        echo "========================"
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  status, st   - Show current GTK theme"
        echo "  set <theme>  - Set GTK theme"
        echo "  dark         - Set to Orchis-Dark"
        echo "  light        - Set to Breeze"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 set Orchis"
        echo "  $0 dark"
        echo ""
        exit 0
        ;;
esac
