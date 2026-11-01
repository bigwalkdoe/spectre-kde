#!/usr/bin/env bash
# spectre-kde -- scripts/manage-splash.sh
# Manage the Plasma splash screen theme
# Usage: ./scripts/manage-splash.sh [list|current|set <name>|reset]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/scripts/splash-theme-path.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

list_splash() {
    echo -e "${BLUE}Available splash themes (look-and-feel packages with contents/splash):${NC}"
    echo "=================================================================="
    local found=0
    while IFS= read -r root; do
        [ -d "$root" ] || continue
        for d in "$root"/*/; do
            [ -f "$d/contents/splash/Splash.qml" ] || continue
            echo "  $(basename "$d")"
            found=1
        done
    done < <(_splash_lnf_roots)
    if [ "$found" -eq 0 ]; then
        echo -e "${YELLOW}  none found${NC}"
    fi
    echo "=================================================================="
    echo -e "\n${BLUE}Current:${NC} $(kreadconfig6 --file ksplashrc --group KSplash --key Theme 2>/dev/null || echo '(unset)')"
}

current_splash() {
    local t e
    t="$(kreadconfig6 --file ksplashrc --group KSplash --key Theme 2>/dev/null || echo '(unset)')"
    e="$(kreadconfig6 --file ksplashrc --group KSplash --key Engine 2>/dev/null || echo '(unset)')"
    echo -e "${BLUE}Current splash:${NC} $t (engine: $e)"
    if [ "$t" != "(unset)" ]; then
        if splash_theme_path "$t" >/dev/null 2>&1; then
            echo -e "${GREEN}  resolves: $(splash_theme_path "$t")${NC}"
        else
            echo -e "${RED}  does NOT resolve${NC}"
        fi
    fi
}

set_splash() {
    local name="$1"
    if ! splash_theme_path "$name" >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} splash theme '$name' not found"
        echo "Use '$0 list' to see available themes"
        return 1
    fi
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$name"
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
    echo -e "${GREEN}Splash set to: $name${NC}"
    echo -e "${BLUE}Re-login (or restart ksplash) to see it${NC}"
}

reset_splash() {
    # Clear the theme so KSplash falls back to the active look-and-feel's splash
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme ""
    echo -e "${GREEN}Splash reset (falls back to active look-and-feel)${NC}"
}

case "${1:-list}" in
    list|ls) list_splash ;;
    current|status|st) current_splash ;;
    set)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} provide a theme name"
            echo "Usage: $0 set <name>"
            exit 1
        fi
        set_splash "$2"
        ;;
    reset) reset_splash ;;
    *)
        echo -e "${BLUE}spectre-kde Splash Manager${NC}"
        echo "==========================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls      - List available splash themes"
        echo "  current, st   - Show current splash theme"
        echo "  set <name>    - Set the splash theme"
        echo "  reset         - Reset to active look-and-feel splash"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 set AppleSplash"
        echo "  $0 reset"
        echo ""
        exit 0
        ;;
esac