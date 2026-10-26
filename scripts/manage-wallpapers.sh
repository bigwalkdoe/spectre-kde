#!/usr/bin/env bash
# spectre-kde -- scripts/manage-wallpapers.sh
# Per-monitor wallpaper management
# Usage: ./scripts/manage-wallpapers.sh [list|set <screen> <wallpaper>|clear <screen>|apply]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WALLPAPER_DIR="$HOME/.local/share/wallpapers/kde-setup-02"
VENDORED_DIR="$ROOT/assets/wallpapers"
CONFIG="$ROOT/scripts/wallpapers-config"
DEFAULT_WALLPAPER="wavy_lines_v02_5120x2880.png"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

list_available() {
    echo -e "${BLUE}Available wallpapers:${NC}"
    echo "======================="
    echo -e "${GREEN}Vendored:${NC}"
    if [ -d "$VENDORED_DIR" ]; then
        for f in "$VENDORED_DIR"/*.{png,jpg,jpeg,webp}; do [ -f "$f" ] || continue; echo "  $(basename "$f")"; done
    fi
    echo -e "${GREEN}Installed:${NC}"
    if [ -d "$WALLPAPER_DIR" ]; then
        for f in "$WALLPAPER_DIR"/*.{png,jpg,jpeg,webp}; do [ -f "$f" ] || continue; echo "  $(basename "$f")"; done
    fi
    echo "======================="
}

get_wallpaper_for_screen() {
    local n="$1"
    # Use bash array-ish eval from config
    local val
    val=$(bash -c "source '$CONFIG' && echo \"\${WALLPAPER_$n:-}\"")
    echo "$val"
}

set_wallpaper_for_screen() {
    local n="$1"
    local wp="$2"
    if ! grep -q "^WALLPAPER_$n=" "$CONFIG"; then
        echo "WALLPAPER_$n=\"$wp\"" >> "$CONFIG"
        echo -e "${GREEN}Added:${NC} WALLPAPER_$n=$wp"
    else
        sed -i "s|^WALLPAPER_$n=.*|WALLPAPER_$n=\"$wp\"|" "$CONFIG"
        echo -e "${GREEN}Updated:${NC} WALLPAPER_$n=$wp"
    fi
}

clear_wallpaper_for_screen() {
    local n="$1"
    sed -i "s|^WALLPAPER_$n=.*|WALLPAPER_$n=|" "$CONFIG"
    echo -e "${GREEN}Cleared:${NC} WALLPAPER_$n (falls back to default)"
}

apply_all() {
    echo -e "${YELLOW}Applying per-monitor wallpapers...${NC}"
    local applied=0
    local skipped=0
    local n=1
    while [ "$n" -le 10 ]; do
        local wp
        wp=$(get_wallpaper_for_screen "$n")
        if [ -n "$wp" ]; then
            # resolve path
            local full_path=""
            if [ -f "$wp" ]; then
                full_path="$(realpath "$wp")"
            elif [ -f "$WALLPAPER_DIR/$wp" ]; then
                full_path="$WALLPAPER_DIR/$wp"
            elif [ -f "$VENDORED_DIR/$wp" ]; then
                mkdir -p "$WALLPAPER_DIR"
                cp -f "$VENDORED_DIR/$wp" "$WALLPAPER_DIR/$wp"
                full_path="$WALLPAPER_DIR/$wp"
            else
                echo -e "${RED}Error: wallpaper not found for screen $n: $wp${NC}"
                skipped=$((skipped+1))
                n=$((n+1))
                continue
            fi
            echo -e "${BLUE}Applying wallpaper to screen $n:${NC} $(basename "$full_path")"
            if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
                plasma-apply-wallpaperimage "$full_path" && applied=$((applied+1))
            elif command -v qdbus6 >/dev/null 2>&1; then
                qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
                    "var allDesktops = desktops(); for (i=0; i<allDesktops.length; i++) { d = allDesktops[i]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); d.writeConfig('Image', 'file://$full_path') }" \
                    && applied=$((applied+1))
            fi
        fi
        n=$((n+1))
    done
    echo -e "${GREEN}✓ Applied wallpapers to $applied screen(s)${NC}"
}

case "${1:-list}" in
    list)
        echo -e "${BLUE}Per-monitor wallpaper assignments:${NC}"
        echo "=============================="
        source "$CONFIG"
        for i in 1 2 3 4 5 6 7 8 9 10; do
            eval "val=\"\$WALLPAPER_$i\""
            printf '  Screen %d: %s\n' "$i" "${val:-<default>}"
        done
        echo "=============================="
        ;;
    set)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo -e "${RED}Error:${NC} Usage: $0 set <screen> <wallpaper>"
            exit 1
        fi
        set_wallpaper_for_screen "$2" "$3"
        echo -e "${BLUE}Use '$0 apply' to push to the live session${NC}"
        ;;
    clear)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Usage: $0 clear <screen>"
            exit 1
        fi
        clear_wallpaper_for_screen "$2"
        echo -e "${BLUE}Use '$0 apply' to push to the live session${NC}"
        ;;
    apply)
        apply_all
        ;;
    *)
        echo -e "${BLUE}spectre-kde Per-Monitor Wallpaper Manager${NC}"
        echo "========================================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list       - List per-screen wallpaper assignments"
        echo "  set <n> <wp>  - Set wallpaper for screen n (e.g., 2 for second screen)"
        echo "  clear <n>    - Clear wallpaper for screen n (back to default)"
        echo "  apply      - Apply all per-screen wallpapers to the live session"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 set 2 ~/Pictures/second.jpg"
        echo "  $0 set 2 wavy_lines_v02_5120x2880.png"
        echo "  $0 clear 2"
        echo "  $0 apply"
        echo ""
        ;;
esac
