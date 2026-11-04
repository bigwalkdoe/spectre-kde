#!/usr/bin/env bash
# spectre-kde -- scripts/show-all-status.sh
# Comprehensive status overview

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}=== SPECTRE-KDE COMPREHENSIVE STATUS ===${NC}"
echo ""

echo -e "${BOLD}Theme:${NC}"
lnf_pkg="$(kreadconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key LookAndFeelPackage 2>/dev/null || true)"
echo "  Global Theme: ${lnf_pkg:-unknown}"
echo ""

echo -e "${BOLD}Panels:${NC}"
if [ -f "$HOME/.config/plasmashellrc" ]; then
    echo "  Config: $(grep -c '\[PlasmaViews\]\[Panel' "$HOME/.config/plasmashellrc" 2>/dev/null || echo 0) panel sections"
fi
echo ""

echo -e "${BOLD}Backups:${NC}"
backup_count=$(find "$HOME/.config/kde-backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || true)
echo "  Available: $backup_count"
echo ""

echo -e "${BOLD}Managers:${NC}"
[ -f "$HOME/.config/kcminputrc" ] && echo "  ✓ Cursor configured"
[ -f "$HOME/.config/kwinrc" ] && echo "  ✓ KWin configured"
[ -f "$HOME/.config/kdeglobals" ] && echo "  ✓ Global theme configured"
echo ""

echo -e "${BOLD}Scripts:${NC}"
echo "  Available: $(ls "$ROOT"/scripts/manage-*.sh 2>/dev/null | wc -l) managers"
echo ""
