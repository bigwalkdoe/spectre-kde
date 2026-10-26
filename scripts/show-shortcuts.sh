#!/usr/bin/env bash
# spectre-kde -- scripts/show-shortcuts.sh
# Display current keyboard shortcuts in a nice format

set -euo pipefail

BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                    KEYBOARD SHORTCUTS                        ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Window Management${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  %-30s %s\n" "Meta+W" "Overview (Mission Control)"
printf "  %-30s %s\n" "Meta+G" "Grid View"
printf "  %-30s %s\n" "Meta+D" "Show Desktop"
printf "  %-30s %s\n" "Meta+T" "Tiles Editor"
printf "  %-30s %s\n" "Meta+Ctrl+Left/Right" "Switch Desktop"
printf "  %-30s %s\n" "Shift+Meta+Ctrl+Left/Right" "Move Window to Desktop"
echo ""

echo -e "${BLUE}Application Launcher${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  %-30s %s\n" "Meta (or Alt+F1)" "Application Launcher"
printf "  %-30s %s\n" "Alt+F2" "KRunner"
printf "  %-30s %s\n" "Alt+Tab / Meta+Tab" "Window Switcher"
echo ""

echo -e "${BLUE}KWin Effects${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  %-30s %s\n" "Ctrl+F9 / Meta+F9" "Present Windows (Current Desktop)"
printf "  %-30s %s\n" "Ctrl+F10 / Meta+F10" "Present Windows (All Desktops)"
echo ""

echo -e "${CYAN}Note:${NC} These are KDE Plasma defaults. spectre-kde keeps them intact."
echo ""
