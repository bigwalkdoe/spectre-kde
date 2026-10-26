#!/usr/bin/env bash
# spectre-kde -- quick-update.sh
# Quick update of dock and panels without full theme reapply

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Quick update: Dock and Panel Layout${NC}"
echo ""

# Load dock configuration
DOCK_CFG="$ROOT/scripts/dock-config"
# shellcheck disable=SC1090  # path is computed from $ROOT at runtime
[ -f "$DOCK_CFG" ] && . "$DOCK_CFG" || true
DOCK_POSITION="${DOCK_POSITION:-bottom}"
DOCK_HEIGHT_MULTIPLIER="${DOCK_HEIGHT_MULTIPLIER:-26/9}"
DOCK_FLOATING="${DOCK_FLOATING:-true}"
DOCK_CENTERED="${DOCK_CENTERED:-true}"

# Load topbar configuration
TOPBAR_CFG="$ROOT/scripts/topbar-config"
# shellcheck disable=SC1090  # path is computed from $ROOT at runtime
[ -f "$TOPBAR_CFG" ] && . "$TOPBAR_CFG" || true
TOPBAR_HEIGHT_MULTIPLIER="${TOPBAR_HEIGHT_MULTIPLIER:-10/6}"
TOPBAR_SHOW_APP_MENU="${TOPBAR_SHOW_APP_MENU:-true}"
TOPBAR_SHOW_PAGER="${TOPBAR_SHOW_PAGER:-true}"
TOPBAR_SHOW_TRAY="${TOPBAR_SHOW_TRAY:-true}"
TOPBAR_SHOW_CLOCK="${TOPBAR_SHOW_CLOCK:-true}"

# Resolve the pinned dock launchers
echo -e "${YELLOW}Resolving dock launchers...${NC}"
DOCK_LAUNCHERS="$(bash "$ROOT/scripts/resolve-launchers.sh" "$ROOT/scripts/dock-launchers.list")" \
  || { echo "Failed to resolve launchers"; exit 1; }

case "$DOCK_LAUNCHERS" in
  *[!A-Za-z0-9.,:_-]*) echo "Invalid launcher list"; exit 1 ;;
esac

LAYOUT_JS="$(sed -e "s|@DOCK_LAUNCHERS@|$DOCK_LAUNCHERS|g" \
                  -e "s|@DOCK_POSITION@|$DOCK_POSITION|g" \
                  -e "s|@DOCK_HEIGHT_MULTIPLIER@|$DOCK_HEIGHT_MULTIPLIER|g" \
                  -e "s|@DOCK_FLOATING@|$DOCK_FLOATING|g" \
                  -e "s|@DOCK_CENTERED@|$DOCK_CENTERED|g" \
                  -e "s|@TOPBAR_HEIGHT_MULTIPLIER@|$TOPBAR_HEIGHT_MULTIPLIER|g" \
                  -e "s|@TOPBAR_SHOW_APP_MENU@|$TOPBAR_SHOW_APP_MENU|g" \
                  -e "s|@TOPBAR_SHOW_PAGER@|$TOPBAR_SHOW_PAGER|g" \
                  -e "s|@TOPBAR_SHOW_TRAY@|$TOPBAR_SHOW_TRAY|g" \
                  -e "s|@TOPBAR_SHOW_CLOCK@|$TOPBAR_SHOW_CLOCK|g" \
                  "$ROOT/scripts/layout.js")" \
  || { echo "Failed to render layout"; exit 1; }

case "$LAYOUT_JS" in
  *@DOCK_LAUNCHERS@*) echo "Unresolved token in layout"; exit 1 ;;
esac

echo -e "${YELLOW}Applying panel layout...${NC}"
LAYOUT_OUT="$(gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
  --method org.kde.PlasmaShell.evaluateScript "$LAYOUT_JS" 2>&1)" || { echo "Layout failed: $LAYOUT_OUT"; exit 1; }
echo "$LAYOUT_OUT"
echo "$LAYOUT_OUT" | grep -q "layout complete" || { echo "Layout did not complete"; exit 1; }

echo -e "${YELLOW}Curating system tray...${NC}"
TRAY_OUT="$(gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
  --method org.kde.PlasmaShell.evaluateScript "$(cat "$ROOT/scripts/tray-config.js")" 2>&1)" || { echo "Tray failed: $TRAY_OUT"; exit 1; }
echo "$TRAY_OUT"

echo -e "${YELLOW}Setting panel visibility (dodge windows)...${NC}"
bash "$ROOT/scripts/set-panel-visibility.sh" "$LAYOUT_OUT" 2 \
  || { echo "Failed to set panel visibility"; exit 1; }

echo -e "${GREEN}✓ Quick update complete!${NC}"
echo "Changes to dock/apps/tray should be applied immediately."
