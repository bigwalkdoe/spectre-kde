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

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/plasma.sh
source "$ROOT/scripts/lib/plasma.sh"

DOCK_PANEL="${1:-}"
FIT="${2:-${DOCK_FIT_TO_CONTENT:-true}}"
CENTERED="${3:-${DOCK_CENTERED:-true}}"
FLOATING="${4:-${DOCK_FLOATING:-true}}"
RC_FILE="${PLASMASHELLRC_PATH:-$(plasma_rc_file)}"

if [ -z "$DOCK_PANEL" ]; then
    log_err "dock panel id required"
    exit 1
fi

# Base panel view settings
if [ "$CENTERED" = "true" ]; then
    write_panel_setting "$RC_FILE" "$DOCK_PANEL" "alignment" "132"
else
    write_panel_setting "$RC_FILE" "$DOCK_PANEL" "alignment" "1"
fi

if [ "$FLOATING" = "true" ]; then
    write_panel_setting "$RC_FILE" "$DOCK_PANEL" "floating" "1"
fi

if [ "$FIT" = "true" ]; then
    write_panel_defaults "$RC_FILE" "$DOCK_PANEL" "minLength" "-1"
    write_panel_defaults "$RC_FILE" "$DOCK_PANEL" "maxLength" "-1"
    # Update all existing screen-specific subgroups (Defaults handled above).
    for grp in $(get_panel_subgroups "$RC_FILE" "$DOCK_PANEL"); do
        [ "$grp" = "Defaults" ] && continue
        write_panel_subgroup "$RC_FILE" "$DOCK_PANEL" "$grp" "minLength" "-1"
        write_panel_subgroup "$RC_FILE" "$DOCK_PANEL" "$grp" "maxLength" "-1"
    done
    gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fit';}" >/dev/null 2>&1 || true
else
    gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "var p=panelById($DOCK_PANEL); if(p){p.lengthMode='fill';}" >/dev/null 2>&1 || true
fi
