#!/usr/bin/env bash
# spectre-kde -- scripts/enforce-dock-view-settings.sh
# Reapply persisted dock panel view settings for the current dock panel.
#
# Useful after monitor/resolution changes or reboot when Plasma creates new
# screen-specific [PlasmaViews][Panel <id>][...] subgroups that don't yet have
# fit/alignment settings. set-dock-view-settings.sh updates Defaults and all
# existing subgroups for the target panel at time of run.
#
# Usage: ./scripts/enforce-dock-view-settings.sh [dock_panel_id]
# If dock_panel_id is omitted, detect the dock panel by finding the panel
# containment that contains org.kde.plasma.icontasks in appletsrc.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/plasma.sh
source "$ROOT/scripts/lib/plasma.sh"

DOCK_CFG="$ROOT/scripts/dock-config"
# shellcheck disable=SC1090
[ -f "$DOCK_CFG" ] && . "$DOCK_CFG" || true
DOCK_FIT_TO_CONTENT="${DOCK_FIT_TO_CONTENT:-true}"
DOCK_CENTERED="${DOCK_CENTERED:-true}"
DOCK_FLOATING="${DOCK_FLOATING:-true}"

DOCK_PANEL="${1:-}"
if [ -z "$DOCK_PANEL" ]; then
    DOCK_PANEL="$(detect_dock_panel_id)" || {
        log_err "could not detect dock panel (icontasks panel containment)"
        exit 1
    }
fi

bash "$ROOT/scripts/set-dock-view-settings.sh" "$DOCK_PANEL" "$DOCK_FIT_TO_CONTENT" "$DOCK_CENTERED" "$DOCK_FLOATING"
log_ok "applied dock view settings to panel $DOCK_PANEL"
