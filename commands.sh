#!/usr/bin/env bash
# spectre-kde -- commands.sh
# Quick reference of all available commands

BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}SPECTRE-KDE COMMAND REFERENCE${NC}"
echo "==============================="
echo ""

echo -e "${BLUE}Main Scripts:${NC}"
printf "  %-30s %s\n" "./menu.sh" "Interactive menu (all features)"
printf "  %-30s %s\n" "./apply.sh [--light|--dark]" "Apply theme configuration"
printf "  %-30s %s\n" "./quick-update.sh" "Update dock/panels/tray only"
printf "  %-30s %s\n" "./verify.sh" "Verify configuration"
printf "  %-30s %s\n" "./status.sh" "Quick status"
printf "  %-30s %s\n" "./health.sh" "Health dashboard"
printf "  %-30s %s\n" "./doctor.sh" "Diagnose issues"
echo ""

echo -e "${BLUE}Maintenance:${NC}"
printf "  %-30s %s\n" "./backup.sh" "Create backup"
printf "  %-30s %s\n" "./rollback.sh" "Restore last backup"
printf "  %-30s %s\n" "./sync.sh" "Sync live config to repo"
printf "  %-30s %s\n" "./update.sh" "Pull updates and reapply"
printf "  %-30s %s\n" "./reset.sh" "Reset to defaults"
printf "  %-30s %s\n" "./fix-issues.sh" "Auto-fix common issues"
echo ""

echo -e "${BLUE}Utilities:${NC}"
printf "  %-30s %s\n" "./detect.sh" "Environment inventory"
printf "  %-30s %s\n" "./welcome.sh" "Getting started guide"
printf "  %-30s %s\n" "./scripts/preflight-check.sh" "Validate before apply"
printf "  %-30s %s\n" "./scripts/diff-config.sh" "Compare live vs repo config"
printf "  %-30s %s\n" "./scripts/export-config.sh" "Export full config"
echo ""

echo -e "${BLUE}Managers:${NC}"
printf "  %-30s %s\n" "./scripts/manage-dock.sh" "Manage dock apps"
printf "  %-30s %s\n" "./scripts/manage-wallpapers.sh" "Per-monitor wallpapers"
printf "  %-30s %s\n" "./scripts/manage-kwin-rules.sh" "Window rules"
printf "  %-30s %s\n" "./scripts/manage-nightlight.sh" "Night Color"
printf "  %-30s %s\n" "./scripts/manage-fonts.sh" "Font management"
printf "  %-30s %s\n" "./scripts/manage-notifications.sh" "Notifications"
printf "  %-30s %s\n" "./scripts/manage-power.sh" "Power profiles"
echo ""
