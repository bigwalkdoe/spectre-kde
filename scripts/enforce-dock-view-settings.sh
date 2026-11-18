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
APP="${PLASMA_APPLETSRC_PATH:-$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc}"
DOCK_CFG="$ROOT/scripts/dock-config"

# shellcheck disable=SC1090
[ -f "$DOCK_CFG" ] && . "$DOCK_CFG" || true
DOCK_FIT_TO_CONTENT="${DOCK_FIT_TO_CONTENT:-true}"
DOCK_CENTERED="${DOCK_CENTERED:-true}"
DOCK_FLOATING="${DOCK_FLOATING:-true}"

DOCK_PANEL="${1:-}"
if [ -z "$DOCK_PANEL" ]; then
  if [ -f "$APP" ]; then
    DOCK_PANEL="$(awk '
      /^\[Containments\]\[[0-9]+\]$/ {
        if (id != "" && is_panel && has_tasks) print id
        id=$0; gsub(/[^0-9]/,"",id); is_panel=0; has_tasks=0; next
      }
      /^plugin=org\.kde\.panel$/ { is_panel=1; next }
      /^plugin=org\.kde\.plasma\.icontasks$/ { has_tasks=1; next }
      END { if (id != "" && is_panel && has_tasks) print id }
    ' "$APP" | head -n 1)"
  fi
fi

if [ -z "$DOCK_PANEL" ]; then
  echo "enforce-dock-view-settings: could not detect dock panel (icontasks panel containment) in $APP" >&2
  exit 1
fi

bash "$ROOT/scripts/set-dock-view-settings.sh" "$DOCK_PANEL" "$DOCK_FIT_TO_CONTENT" "$DOCK_CENTERED" "$DOCK_FLOATING"
echo "enforce-dock-view-settings: applied dock view settings to panel $DOCK_PANEL"
