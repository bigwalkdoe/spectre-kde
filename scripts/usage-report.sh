#!/usr/bin/env bash
# spectre-kde -- scripts/usage-report.sh
# Show disk usage of configs and backups

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$HOME/.config"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}Configuration Disk Usage${NC}"
echo "=========================="
echo ""

echo -e "${GREEN}KDE Config Files:${NC}"
du -sh "$CFG/plasma"* "$CFG/kde*" "$CFG/kwin*" "$CFG/ksplashrc" "$CFG/baloo*" "$CFG/power*" 2>/dev/null | sort -hr
echo ""

echo -e "${GREEN}GTK Config:${NC}"
du -sh "$CFG/gtk-3.0" "$CFG/gtk-4.0" 2>/dev/null
echo ""

echo -e "${GREEN}Backups:${NC}"
du -sh "$HOME/.config/kde-backups" 2>/dev/null
echo -e "  Count: $(ls -1d "$HOME/.config/kde-backups/"*/ 2>/dev/null | wc -l) directories"
echo ""

echo -e "${GREEN}Fonts:${NC}"
du -sh "$HOME/.local/share/fonts" 2>/dev/null
echo ""

echo -e "${GREEN}Wallpapers:${NC}"
du -sh "$HOME/.local/share/wallpapers" 2>/dev/null
echo ""
