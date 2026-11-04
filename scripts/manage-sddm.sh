#!/usr/bin/env bash
# spectre-kde -- scripts/manage-sddm.sh
# Manage the SDDM display manager theme
# Usage: ./scripts/manage-sddm.sh [status|install|reinstall|current]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONF="${SDDM_CONF:-/etc/sddm.conf.d/theme.conf}"
THEME_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes}"
NAME="${SDDM_THEME_NAME:-Orchis-Mac}"

status_sddm() {
    echo -e "${BLUE}SDDM Status:${NC}"
    echo "========================================"
    if [ -f "$CONF" ]; then
        echo -e "${GREEN}Config:${NC} $CONF exists"
        if grep -q "^Current=$NAME$" "$CONF" 2>/dev/null; then
            echo -e "${GREEN}Current theme:${NC} $NAME"
        else
            local cur
            cur="$(grep '^Current=' "$CONF" 2>/dev/null | cut -d= -f2 || echo '(unset)')"
            echo -e "${YELLOW}Current theme:${NC} $cur"
        fi
        grep -q "^CursorTheme=" "$CONF" && echo -e "  CursorTheme: $(grep '^CursorTheme=' "$CONF" | cut -d= -f2)"
        grep -q "^Font=" "$CONF" && echo -e "  Font: $(grep '^Font=' "$CONF" | cut -d= -f2-)"
    else
        echo -e "${RED}Config:${NC} $CONF not found"
    fi
    echo ""
    if [ -d "$THEME_DIR/$NAME" ]; then
        echo -e "${GREEN}Theme installed:${NC} $THEME_DIR/$NAME"
    else
        echo -e "${RED}Theme installed:${NC} Not found"
    fi
    echo "========================================"
}

current_sddm() {
    status_sddm
}

install_sddm() {
    echo -e "${BLUE}Installing Orchis-Mac SDDM theme...${NC}"
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${YELLOW}Root privileges required. Running with sudo...${NC}"
        exec sudo "$ROOT/scripts/install-sddm-orchis.sh" "$@"
    else
        "$ROOT/scripts/install-sddm-orchis.sh" "$@"
    fi
}

reinstall_sddm() {
    echo -e "${BLUE}Reinstalling Orchis-Mac SDDM theme...${NC}"
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${YELLOW}Root privileges required. Running with sudo...${NC}"
        exec sudo "$ROOT/scripts/install-sddm-orchis.sh" --force "$@"
    else
        "$ROOT/scripts/install-sddm-orchis.sh" --force "$@"
    fi
}

case "${1:-status}" in
    status|current|st) status_sddm ;;
    install) install_sddm ;;
    reinstall|force) reinstall_sddm ;;
    *)
        echo -e "${BLUE}spectre-kde SDDM Manager${NC}"
        echo "=========================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status, st    - Show current SDDM status"
        echo "  install       - Install Orchis-Mac SDDM theme"
        echo "  reinstall     - Force reinstall Orchis-Mac SDDM theme"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 install"
        echo "  $0 reinstall"
        echo ""
        exit 0
        ;;
esac
