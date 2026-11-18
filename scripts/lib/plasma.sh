#!/usr/bin/env bash
# spectre-kde -- scripts/lib/plasma.sh
# Shared Plasma/KDE utilities for panel detection, config management, etc.
# Source this file: source "$ROOT/scripts/lib/plasma.sh"

set -euo pipefail

# --- Color constants ---
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    NC="$(tput sgr0)"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# --- Logging helpers ---
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()   { echo -e "${RED}[ERR]${NC}  $*" >&2; }

# --- Plasma config paths ---
plasma_rc_file() {
    echo "${HOME}/.config/plasmashellrc"
}

plasma_appletsrc_file() {
    echo "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"
}

# --- Panel detection ---

# Get all panel containment IDs from appletsrc
# Output: space-separated list of panel IDs
get_panel_ids_from_appletsrc() {
    local appletsrc="${1:-$(plasma_appletsrc_file)}"
    awk '/^\[Containments\]\[[0-9]+\]/{id=$0; gsub(/[^0-9]/,"",id)} /plugin=org.kde.panel/{print id}' "$appletsrc" 2>/dev/null | sort -u | tr '\n' ' '
}

# Detect the dock panel ID by finding the panel containment with icontasks
# Output: dock panel ID or empty string if not found
# Exit code: 0 if found, 1 if not found
detect_dock_panel_id() {
    local appletsrc="${1:-$(plasma_appletsrc_file)}"
    # Two-pass approach:
    # 1. Collect all panel containment IDs
    # 2. Check which ones have icontasks applets
    local panel_ids
    panel_ids=$(awk '/^\[Containments\]\[([0-9]+)\]$/ {cid=$0; gsub(/[^0-9]/,"",cid)} /^plugin=org\.kde\.panel$/ {print cid}' "$appletsrc" | sort -u)
    
    if [ -z "$panel_ids" ]; then
        return 1
    fi
    
    # For each panel ID, check if it has icontasks
    while IFS= read -r pid; do
        [ -z "$pid" ] && continue
        # Check if this panel has icontasks applet
        if awk -v pid="$pid" '
            /^\[Containments\]\['"$pid"'\]\[Applets\]/ { in_applet=1 }
            /^\[Containments\]\[[0-9]+\]\[Applets\]/ && !/^\[Containments\]\['"$pid"'\]\[Applets\]/ { in_applet=0 }
            in_applet && /^plugin=org\.kde\.plasma\.icontasks$/ { found=1 }
            END { exit found ? 0 : 1 }
        ' "$appletsrc"; then
            echo "$pid"
            return 0
        fi
    done <<< "$panel_ids"
    
    return 1
}

# Extract panel IDs from layout.js output (format: panelIds=X,Y)
# Output: first (top) panel ID, second (bottom/dock) panel ID
extract_panel_ids_from_layout() {
    local layout_output="$1"
    local ids
    ids=$(echo "$layout_output" | grep -oE 'panelIds=[0-9]+,[0-9]+' | head -1 | cut -d= -f2)
    if [ -n "$ids" ]; then
        echo "$ids"
    fi
}

# Get dock panel ID from layout output (second ID in panelIds)
# Output: dock panel ID or empty string
get_dock_panel_id_from_layout() {
    local layout_output="$1"
    local ids
    ids=$(extract_panel_ids_from_layout "$layout_output")
    if [ -n "$ids" ]; then
        echo "$ids" | cut -d, -f2
    fi
}

# Get top panel ID from layout output (first ID in panelIds)
get_top_panel_id_from_layout() {
    local layout_output="$1"
    local ids
    ids=$(extract_panel_ids_from_layout "$layout_output")
    if [ -n "$ids" ]; then
        echo "$ids" | cut -d= -f2 | cut -d, -f1
    fi
}

# --- Config helpers ---

# Safe kwriteconfig6 wrapper - suppresses errors for missing keys/groups
kwrite() {
    local file="$1"; shift
    kwriteconfig6 --file "$file" "$@" 2>/dev/null || true
}

# Safe kreadconfig6 wrapper - returns empty string if key not found
kread() {
    local file="$1"; shift
    kreadconfig6 --file "$file" "$@" 2>/dev/null || true
}

# Write a PlasmaViews panel setting
# Usage: write_panel_setting <rc_file> <panel_id> <key> <value>
write_panel_setting() {
    local rc_file="$1" panel_id="$2" key="$3" value="$4"
    kwrite "$rc_file" --group PlasmaViews --group "Panel $panel_id" --key "$key" "$value"
}

# Write a PlasmaViews panel Defaults setting
# Usage: write_panel_defaults <rc_file> <panel_id> <key> <value>
write_panel_defaults() {
    local rc_file="$1" panel_id="$2" key="$3" value="$4"
    kwrite "$rc_file" --group PlasmaViews --group "Panel $panel_id" --group Defaults --key "$key" "$value"
}

# Write a PlasmaViews panel screen-specific subgroup setting
# Usage: write_panel_subgroup <rc_file> <panel_id> <subgroup> <key> <value>
write_panel_subgroup() {
    local rc_file="$1" panel_id="$2" subgroup="$3" key="$4" value="$5"
    kwrite "$rc_file" --group PlasmaViews --group "Panel $panel_id" --group "$subgroup" --key "$key" "$value"
}

# Read a PlasmaViews panel setting
# Usage: read_panel_setting <rc_file> <panel_id> <key>
read_panel_setting() {
    local rc_file="$1" panel_id="$2" key="$3"
    kread "$rc_file" --group PlasmaViews --group "Panel $panel_id" --key "$key"
}

# Get existing screen-specific subgroups for a panel
# Output: space-separated subgroup names (e.g., "Horizontal1920 Vertical1080")
get_panel_subgroups() {
    local rc_file="$1" panel_id="$2"
    grep -oE "^\[PlasmaViews\]\[Panel ${panel_id}\]\[[^]]+\]" "$rc_file" 2>/dev/null | sed 's/.*\]\[\([^]]*\)\]$/\1/' | tr '\n' ' '
}

# --- Plasmashell helpers ---

# Restart plasmashell gracefully
restart_plasmashell() {
    systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
    sleep 0.5
    systemctl --user start plasma-plasmashell.service 2>/dev/null || true
    sleep 1
}

# Check if we're running in a Plasma session
is_plasma_session() {
    [ -n "${KDE_FULL_SESSION:-}" ] || [ -n "${KDE_SESSION_VERSION:-}" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ]
}

# --- Wallpaper helpers ---

# Get current wallpaper plugin for a containment
get_wallpaper_plugin() {
    local containment_id="$1"
    local appletsrc="${2:-$(plasma_appletsrc_file)}"
    awk -v cid="Containments][$containment_id]" '
        $0 ~ "\\[" cid "\\]" { in_section=1 }
        in_section && /^wallpaperplugin=/ { print $0; exit }
        in_section && /^\[/ && !/^\['"cid"'\]/ { in_section=0 }
    ' "$appletsrc" 2>/dev/null | cut -d= -f2
}

# --- Export functions ---
export -f log_info log_ok log_warn log_err
export -f plasma_rc_file plasma_appletsrc_file
export -f get_panel_ids_from_appletsrc detect_dock_panel_id
export -f extract_panel_ids_from_layout get_dock_panel_id_from_layout get_top_panel_id_from_layout
export -f kwrite kread
export -f write_panel_setting write_panel_defaults write_panel_subgroup read_panel_setting get_panel_subgroups
export -f restart_plasmashell is_plasma_session get_wallpaper_plugin