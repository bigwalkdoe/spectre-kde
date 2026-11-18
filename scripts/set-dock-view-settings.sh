#!/usr/bin/env bash
# spectre-kde -- scripts/set-dock-view-settings.sh
# Persist dock panel view settings (alignment/fit/floating) for a given panel id.
#
# Usage: set-dock-view-settings.sh <dock_panel_id> [fit_to_content] [centered] [floating]
# Defaults: fit_to_content=$DOCK_FIT_TO_CONTENT or true, centered=$DOCK_CENTERED or true,
#           floating=$DOCK_FLOATING or true
#
# Writes to [PlasmaViews][Panel <id>] and updates [Defaults] and any existing
# screen-specific subgroups (e.g. Horizontal1920) so settings survive resolution/
# monitor-group changes where those groups already exist.
set -euo pipefail

DOCK_PANEL="${1:-}"
FIT="${2:-${DOCK_FIT_TO_CONTENT:-true}}"
CENTERED="${3:-${DOCK_CENTERED:-true}}"
FLOATING="${4:-${DOCK_FLOATING:-true}}"
RC_FILE="${PLASMASHELLRC_PATH:-$HOME/.config/plasmashellrc}"

if [ -z "$DOCK_PANEL" ]; then
  echo "set-dock-view-settings: dock panel id required" >&2
  exit 1
fi

# Base panel view settings
if [ "$CENTERED" = "true" ]; then
  kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --key alignment 132 2>/dev/null || true
else
  kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --key alignment 1 2>/dev/null || true
fi

if [ "$FLOATING" = "true" ]; then
  kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --key floating 1 2>/dev/null || true
fi

if [ "$FIT" = "true" ]; then
  kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --group Defaults --key minLength -- "-1" 2>/dev/null || true
  kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --group Defaults --key maxLength -- "-1" 2>/dev/null || true
  # Update all existing screen-specific subgroups (Defaults handled above).
  if [ -f "$RC_FILE" ]; then
    while IFS= read -r grp; do
      [ -n "$grp" ] || continue
      case "$grp" in Defaults) continue ;; esac
      kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --group "$grp" --key minLength -- "-1" 2>/dev/null || true
      kwriteconfig6 --file "$RC_FILE" --group PlasmaViews --group "Panel $DOCK_PANEL" --group "$grp" --key maxLength -- "-1" 2>/dev/null || true
    done < <(grep -oE "^\[PlasmaViews\]\[Panel ${DOCK_PANEL}\]\[[^]]+\]" "$RC_FILE" 2>/dev/null | sed 's/.*\]\[\([^]]*\)\]$/\1/' || true)
  fi
  gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fit';}" >/dev/null 2>&1 || true
else
  gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fill';}" >/dev/null 2>&1 || true
fi
