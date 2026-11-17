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

say(){ echo; echo "### $*"; }
die(){ echo "FAIL: $*" >&2; exit 1; }

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
DOCK_FIT_TO_CONTENT="${DOCK_FIT_TO_CONTENT:-true}"

# Load topbar configuration
TOPBAR_CFG="$ROOT/scripts/topbar-config"
# shellcheck disable=SC1090  # path is computed from $ROOT at runtime
[ -f "$TOPBAR_CFG" ] && . "$TOPBAR_CFG" || true
TOPBAR_HEIGHT_MULTIPLIER="${TOPBAR_HEIGHT_MULTIPLIER:-10/6}"
TOPBAR_SHOW_APP_MENU="${TOPBAR_SHOW_APP_MENU:-true}"
TOPBAR_SHOW_PAGER="${TOPBAR_SHOW_PAGER:-true}"
TOPBAR_SHOW_NETSPEED="${TOPBAR_SHOW_NETSPEED:-true}"
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
                  -e "s|@DOCK_FIT_TO_CONTENT@|$DOCK_FIT_TO_CONTENT|g" \
                  -e "s|@TOPBAR_HEIGHT_MULTIPLIER@|$TOPBAR_HEIGHT_MULTIPLIER|g" \
                  -e "s|@TOPBAR_SHOW_APP_MENU@|$TOPBAR_SHOW_APP_MENU|g" \
                  -e "s|@TOPBAR_SHOW_PAGER@|$TOPBAR_SHOW_PAGER|g" \
                  -e "s|@TOPBAR_SHOW_NETSPEED@|$TOPBAR_SHOW_NETSPEED|g" \
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
# scripts/curate-tray.sh force-recreates the pinned applets; a plain rewrite
# of an unchanged extraItems list is a no-op to plasmashell.
bash "$ROOT/scripts/curate-tray.sh" || { echo "Tray curation failed"; exit 1; }

echo -e "${YELLOW}Setting panel visibility (dodge windows)...${NC}"
bash "$ROOT/scripts/set-panel-visibility.sh" "$LAYOUT_OUT" 2 \
  || { echo "Failed to set panel visibility"; exit 1; }

echo -e "${YELLOW}Applying top-bar netspeed polish...${NC}"
bash "$ROOT/scripts/set-netspeed-compact.sh" "$LAYOUT_OUT" || true

echo -e "${YELLOW}Cleaning stale plasmashellrc entries...${NC}"
bash "$ROOT/scripts/clean-plasmashellrc.sh" || true

echo -e "${GREEN}✓ Quick update complete!${NC}"
echo "Changes to dock/apps/tray should be applied immediately."

# Persist dock settings so they survive reboots.
DOCK_FIT_TO_CONTENT="${DOCK_FIT_TO_CONTENT:-true}"
DOCK_CENTERED="${DOCK_CENTERED:-true}"
DOCK_FLOATING="${DOCK_FLOATING:-true}"

# layout.js reports panelIds=topPanel,dock
DOCK_PANEL="$(echo "$LAYOUT_OUT" | grep -oE 'panelIds=[0-9]+,[0-9]+' | head -1 | cut -d= -f2 | cut -d, -f2)"
if [ -n "$DOCK_PANEL" ]; then
    if [ "$DOCK_CENTERED" = "true" ]; then
        kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --key alignment 132 2>/dev/null || true
    else
        kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --key alignment 1 2>/dev/null || true
    fi
    if [ "$DOCK_FIT_TO_CONTENT" = "true" ]; then
        # Write fit-to-content in all relevant groups (Defaults + any screen-specific groups)
        kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --group Defaults --key minLength -- "-1" 2>/dev/null || true
        kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --group Defaults --key maxLength -- "-1" 2>/dev/null || true
        # Update any existing screen-specific length groups (e.g. Horizontal1920, Horizontal2560)
        for grp in $(grep -oE "^\[PlasmaViews\]\[Panel ${DOCK_PANEL}\]\[[^]]+\]" ~/.config/plasmashellrc 2>/dev/null | sed 's/.*\]\[\([^]]*\)\]$/\1/'); do
            case "$grp" in Defaults) continue ;; esac
            kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --group "$grp" --key minLength -- "-1" 2>/dev/null || true
            kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --group "$grp" --key maxLength -- "-1" 2>/dev/null || true
        done
        gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fit';}" >/dev/null 2>&1 || true
    else
        gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fill';}" >/dev/null 2>&1 || true
    fi
    if [ "$DOCK_FLOATING" = "true" ]; then
        kwriteconfig6 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel $DOCK_PANEL" --key floating 1 2>/dev/null || true
    fi
fi

# Restart plasmashell so panel geometry/struts (e.g. fit-content dock) are
# picked up correctly for window snapping/maximization and dodge behavior.
echo -e "${YELLOW}Restarting plasmashell to refresh panel geometry...${NC}"
systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
for _ in $(seq 1 30); do
  names="$(busctl --user list --no-pager 2>/dev/null || true)"
  grep -q '^org\.kde\.plasmashell[[:space:]]' <<< "$names" && break
  sleep 1
done

say "Lock screen: ensure system MainBlock.qml is intact"
