#!/usr/bin/env bash
# shellcheck disable=SC2034
# spectre-kde -- welcome.sh
# Getting started guide

set -euo pipefail


CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                      WELCOME TO SPECTRE-KDE                       ║${NC}"
echo -e "${BOLD}${CYAN}║           macOS-inspired KDE Plasma Configuration                  ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BOLD}Quick Start:${NC}"
echo -e "  1. ${GREEN}Check dependencies:${NC}  ./doctor.sh"
echo -e "  2. ${GREEN}Run preflight check:${NC}  ./scripts/preflight-check.sh --light"
echo -e "  3. ${GREEN}Apply configuration:${NC}  ./apply.sh --light (or --dark)"
echo -e "  4. ${GREEN}Verify:${NC}                ./verify.sh"
echo ""

echo -e "${BOLD}Interactive Management:${NC}"
echo -e "  ${CYAN}./menu.sh${NC} - Full interactive menu for all features"
echo ""

echo -e "${BOLD}Key Features:${NC}"
echo -e "  • Clean macOS-style top bar and dock"
echo -e "  • Orchis theme with custom icons and cursor"
echo -e "  • Global menu, system tray, workspace pager"
echo -e "  • Dock with pinned apps, centered and floating"
echo -e "  • Window rules for app placement"
echo -e "  • Night Color (blue light filter)"
echo -e "  • Per-monitor wallpapers"
echo -e "  • Easy theme switching (light/dark)"
echo -e "  • Full backup and rollback support"
echo ""

echo -e "${BOLD}Common Commands:${NC}"
echo -e "  ${YELLOW}./apply.sh --light|--dark${NC}  - Apply theme"
echo -e "  ${YELLOW}./quick-update.sh${NC}         - Update dock/panels without full apply"
echo -e "  ${YELLOW}./status.sh${NC}              - Check current status"
echo -e "  ${YELLOW}./health.sh${NC}              - Health dashboard"
echo -e "  ${YELLOW}./rollback.sh${NC}            - Restore previous backup"
echo ""

echo -e "${CYAN}For more information, see README.md${NC}"
echo ""
read -p "Press Enter to continue..."
