#!/usr/bin/env bash
# shellcheck disable=SC2034
# spectre-kde -- fix-issues.sh
# Automatically fix common issues

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      spectre-kde Auto-Fix Utility      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

fixed=0

# Fix 1: Ensure scripts are executable
echo -e "${YELLOW}[1/6]${NC} Checking script permissions..."
for f in "$ROOT"/*.sh "$ROOT"/scripts/*.sh; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        chmod +x "$f"
        echo -e "  ${GREEN}✓${NC} Fixed permissions: $(basename $f)"
        fixed=$((fixed + 1))
    fi
done
if [ "$fixed" -eq 0 ]; then echo -e "  ${GREEN}✓${NC} All scripts executable"; fi

# Fix 2: Create missing directories
echo -e "\n${YELLOW}[2/6]${NC} Checking directories..."
for d in "$HOME/.config" "$HOME/.local/share/fonts" "$HOME/.local/share/wallpapers/kde-setup-02" "$HOME/.config/kde-backups"; do
    if [ ! -d "$d" ]; then
        mkdir -p "$d"
        echo -e "  ${GREEN}✓${NC} Created: $d"
        fixed=$((fixed + 1))
    fi
done
if [ "$fixed" -eq 0 ]; then echo -e "  ${GREEN}✓${NC} All directories exist"; fi

# Fix 3: Font cache
echo -e "\n${YELLOW}[3/6]${NC} Checking font cache..."
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 && echo -e "  ${GREEN}✓${NC} Font cache rebuilt" && { fixed=$((fixed + 1)); }
fi

# Fix 4: Restart plasmashell if not running
echo -e "\n${YELLOW}[4/6]${NC} Checking plasmashell..."
if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} plasmashell is running"
    else
        echo -e "  ${YELLOW}⚠${NC} plasmashell not active, attempting to start..."
        systemctl --user start plasma-plasmashell.service 2>/dev/null && echo -e "  ${GREEN}✓${NC} Started plasmashell" && { fixed=$((fixed + 1)); } || echo -e "  ${RED}✗${NC} Failed to start plasmashell"
    fi
fi

# Fix 5: Reconfigure KWin
echo -e "\n${YELLOW}[5/6]${NC} Reconfiguring KWin..."
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure 2>/dev/null && echo -e "  ${GREEN}✓${NC} KWin reconfigured" && { fixed=$((fixed + 1)); } || echo -e "  ${YELLOW}⚠${NC} KWin reconfigure skipped"

# Fix 6: Apply window rules if missing
echo -e "\n${YELLOW}[6/6]${NC} Checking window rules..."
if [ ! -f "$HOME/.config/kwinrulesrc" ] && [ -f "$ROOT/config/applied-kwinrulesrc.conf" ]; then
    cp "$ROOT/config/applied-kwinrulesrc.conf" "$HOME/.config/kwinrulesrc"
    echo -e "  ${GREEN}✓${NC} Installed window rules"
    fixed=$((fixed + 1))
    busctl --user call org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
else
    echo -e "  ${GREEN}✓${NC} Window rules OK"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "Issues fixed: ${GREEN}$fixed${NC}"
echo ""
if [ $fixed -gt 0 ]; then
    echo -e "${GREEN}Some issues were fixed. You may need to logout/login for all changes to take effect.${NC}"
else
    echo -e "${GREEN}No issues found or all already fixed.${NC}"
fi
echo ""
