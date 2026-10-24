#!/usr/bin/env bash
# spectre-kde -- manage-wallpaper.sh
# Manage wallpapers for the desktop
# Usage: ./scripts/manage-wallpaper.sh [list|set|current] [path]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WALLPAPER_DIR="$HOME/.local/share/wallpapers/kde-setup-02"
VENDORED_DIR="$ROOT/assets/wallpapers"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_current() {
    if [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        grep -A 5 'Image=' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null | head -2
    fi
}

list_wallpapers() {
    echo -e "${BLUE}Available wallpapers:${NC}"
    echo "====================="
    echo -e "\n${GREEN}Vendored (in repo):${NC}"
    if [ -d "$VENDORED_DIR" ]; then
        for f in "$VENDORED_DIR"/*.{png,jpg,jpeg,webp}; do
            [ -f "$f" ] || continue
            echo "  $(basename "$f")"
        done
    fi
    echo -e "\n${GREEN}Installed:${NC}"
    if [ -d "$WALLPAPER_DIR" ]; then
        for f in "$WALLPAPER_DIR"/*.{png,jpg,jpeg,webp}; do
            [ -f "$f" ] || continue
            echo "  $(basename "$f")"
        done
    fi
    echo "====================="
}

set_wallpaper() {
    local wp="$1"
    local full_path=""
    
    if [ -f "$wp" ]; then
        full_path="$(realpath "$wp")"
    elif [ -f "$WALLPAPER_DIR/$wp" ]; then
        full_path="$WALLPAPER_DIR/$wp"
    elif [ -f "$VENDORED_DIR/$wp" ]; then
        mkdir -p "$WALLPAPER_DIR"
        cp "$VENDORED_DIR/$wp" "$WALLPAPER_DIR/"
        full_path="$WALLPAPER_DIR/$wp"
    else
        echo -e "${RED}Error:${NC} Wallpaper not found: $wp"
        echo "Use '$0 list' to see available wallpapers"
        exit 1
    fi
    
    echo -e "${BLUE}Setting wallpaper to:${NC} $full_path"
    
    # Use plasma-apply-wallpaperimage if available, otherwise use qdbus
    if command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage "$full_path" && echo -e "${GREEN}Wallpaper updated${NC}"
    elif command -v qdbus6 &> /dev/null; then
        # Try to set via DBus
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
            "var allDesktops = desktops(); for (i=0; i<allDesktops.length; i++) { d = allDesktops[i]; d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General'); d.writeConfig('Image', 'file://$full_path') }" \
            && echo -e "${GREEN}Wallpaper updated${NC}"
    else
        echo -e "${YELLOW}Warning:${NC} Could not update wallpaper automatically"
        echo "Please set it manually in System Settings > Appearance > Wallpaper"
    fi
}

case "${1:-list}" in
    list|ls)
        list_wallpapers
        ;;
    current)
        echo -e "${BLUE}Current wallpaper:${NC}"
        get_current
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a wallpaper path or filename"
            echo "Usage: $0 set <filename|/path/to/image>"
            exit 1
        fi
        set_wallpaper "$2"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Wallpaper Manager${NC}"
        echo "=============================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls    - List available wallpapers"
        echo "  current     - Show current wallpaper"
        echo "  set <file>  - Set wallpaper (filename or full path)"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 set wavy_lines_v02_5120x2880.png"
        echo "  $0 set ~/Pictures/mywallpaper.jpg"
        echo ""
        ;;
esac
