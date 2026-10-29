#!/usr/bin/env bash
# spectre-kde -- doctor.sh
# Diagnose common issues and suggest fixes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check() {
    local name="$1"
    local cmd="$2"
    local fix_msg="${3:-}"
    
    echo -n "Checking $name... "
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        ERRORS=$((ERRORS + 1))
        if [ -n "$fix_msg" ]; then
            echo -e "  ${YELLOW}Fix:${NC} $fix_msg"
        fi
    fi
}

warn() {
    local name="$1"
    local cmd="$2"
    local fix_msg="${3:-}"
    
    echo -n "Checking $name... "
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}WARN${NC}"
        WARNINGS=$((WARNINGS + 1))
        if [ -n "$fix_msg" ]; then
            echo -e "  ${YELLOW}Suggestion:${NC} $fix_msg"
        fi
    fi
}

echo "╔════════════════════════════════════════╗"
echo "║          spectre-kde Doctor             ║"
echo "╚════════════════════════════════════════╝"
echo ""

echo -e "${BLUE}Environment${NC}"
check "Plasma session" "[[ \"\$XDG_CURRENT_DESKTOP\" == *KDE* ]] || [[ \"\$XDG_SESSION_DESKTOP\" == *KDE* ]]" "Run this in a KDE Plasma session"
check "Wayland/X11" "[[ -n \"\$WAYLAND_DISPLAY\" ]] || [[ -n \"\$DISPLAY\" ]]" "Need a display server"
echo ""

echo -e "${BLUE}Required Tools${NC}"
check "bash" "command -v bash" "Install bash"
check "plasmashell" "command -v plasmashell" "Install KDE Plasma"
check "gdbus" "command -v gdbus" "Install glib2"
check "busctl" "command -v busctl" "Install systemd"
warn "qdbus6 or qdbus (optional)" "command -v qdbus6 || command -v qdbus" "Install qt6-qttools for the manage-* helper scripts"
check "kwriteconfig6" "command -v kwriteconfig6" "Install kde-cli-tools"
check "plasma-apply-lookandfeel" "command -v plasma-apply-lookandfeel" "Install plasma-workspace"
echo ""

echo -e "${BLUE}Theme Assets${NC}"
warn "Orchis theme" "[ -d \"\$HOME/.local/share/plasma/desktoptheme/Orchis\" ] || [ -d \"/usr/share/plasma/desktoptheme/Orchis\" ]" "Install Orchis theme package"
warn "Orchis-dark theme" "[ -d \"/usr/share/plasma/desktoptheme/Orchis-dark\" ] || find /usr/share -name '*Orchis*dark*' 2>/dev/null | grep -q ." "Install Orchis-dark theme"
warn "Bibata cursor" "[ -d \"\$HOME/.local/share/icons/Bibata-Modern-Ice\" ] || [ -d \"/usr/share/icons/Bibata-Modern-Ice\" ]" "Install bibata-cursor-themes"
warn "FairyWren icons" "find /usr/share/icons /home/\$USER/.local/share/icons -name 'FairyWren*' 2>/dev/null | grep -q ." "Install FairyWren icon theme"
echo ""

echo -e "${BLUE}Configuration${NC}"
check "config directory writable" "[ -w \"\$HOME/.config\" ]" "Fix permissions on ~/.config"
check "local share writable" "[ -w \"\$HOME/.local/share\" ]" "Fix permissions on ~/.local/share"
warn "Backup directory" "[ -d \"\$HOME/.config/kde-backups\" ]" "Will be created on first apply"
echo ""

echo -e "${BLUE}Repository State${NC}"
check "Scripts executable" "[ -x \"$ROOT/apply.sh\" ] && [ -x \"$ROOT/verify.sh\" ]" "Run: chmod +x *.sh scripts/*.sh"
check "No conflicting panels" "[ \$(plasmashell --version >/dev/null && echo ok) ]" ""
echo ""

echo "╔════════════════════════════════════════╗"
echo "║              Summary                   ║"
echo "╚════════════════════════════════════════╝"
echo -e "Errors: ${RED}$ERRORS${NC} | Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ System looks good for spectre-kde!${NC}"
    echo "Run './apply.sh --light' or './apply.sh --dark' to apply configuration."
else
    echo -e "${RED}✗ Some issues found. Please fix errors before applying.${NC}"
    echo "Run './detect.sh' for more detailed information."
fi

if [ $WARNINGS -gt 0 ] && [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Some optional components missing. Configuration may still work.${NC}"
fi
echo ""
