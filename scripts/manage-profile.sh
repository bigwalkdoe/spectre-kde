#!/usr/bin/env bash
# spectre-kde -- scripts/manage-profile.sh
# Manage configuration profiles (export/import/list/apply).
# Profiles bundle dock, top bar, tray, and autostart config inputs.
#
# Usage: ./scripts/manage-profile.sh [list|import <name>|export <name>|apply <name>]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILES_DIR="$ROOT/profiles"

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cmd_list() {
    echo -e "${BLUE}Available profiles:${NC}"
    if [ -d "$PROFILES_DIR" ]; then
        local found=0
        for d in "$PROFILES_DIR"/*/; do
            [ -d "$d" ] || continue
            found=1
            local name desc
            name="$(basename "$d")"
            desc=""
            [ -f "$d/profile-info.txt" ] && desc="$(grep '^Description:' "$d/profile-info.txt" 2>/dev/null | cut -d: -f2- | sed 's/^ //')"
            if [ -n "$desc" ]; then
                printf "  %-12s %s\n" "$name" "$desc"
            else
                printf "  %s\n" "$name"
            fi
        done
        [ "$found" -eq 1 ] || echo "  (none)"
    else
        echo "  (none)"
    fi
}

cmd_show() {
    local name="${1:-}"
    [ -n "$name" ] || { echo "Usage: $0 show <name>"; exit 1; }
    local dir="$PROFILES_DIR/$name"
    [ -d "$dir" ] || { echo "Error: Profile not found: $name" >&2; exit 1; }
    echo -e "${BLUE}Profile:${NC} $name"
    echo "Path: $dir"
    if [ -f "$dir/profile-info.txt" ]; then
        echo ""
        echo "[profile-info.txt]"
        cat "$dir/profile-info.txt"
    fi
    echo ""
    echo "Included files:"
    local f found=0
    for f in dock-launchers.list dock-config topbar-config tray-config.js autostart.list .applied-light .applied-dark profile-info.txt README.md; do
        if [ -f "$dir/$f" ]; then
            printf '  - %s\n' "$f"
            found=1
        fi
    done
    [ "$found" -eq 1 ] || echo "  (none)"
}

case "${1:-list}" in
    list|ls) cmd_list ;;
    show|info)
        cmd_show "${2:-}"
        ;;
    import)
        [ -n "${2:-}" ] || { echo "Usage: $0 import <name>"; exit 1; }
        case "$2" in ''|*[!A-Za-z0-9._-]*) echo "Error: invalid profile name '$2'" >&2; exit 1 ;; esac
        bash "$ROOT/scripts/import-profile.sh" "$2"
        ;;
    export)
        [ -n "${2:-}" ] || { echo "Usage: $0 export <name>"; exit 1; }
        case "$2" in ''|*[!A-Za-z0-9._-]*) echo "Error: invalid profile name '$2'" >&2; exit 1 ;; esac
        bash "$ROOT/scripts/export-profile.sh" "$2"
        ;;
    apply)
        [ -n "${2:-}" ] || { echo "Usage: $0 apply <name>"; exit 1; }
        case "$2" in ''|*[!A-Za-z0-9._-]*) echo "Error: invalid profile name '$2'" >&2; exit 1 ;; esac
        bash "$ROOT/scripts/import-profile.sh" "$2"
        echo -e "${YELLOW}Applying imported profile (quick-update)...${NC}"
        bash "$ROOT/quick-update.sh"
        ;;
    help|-h|--help)
        echo "spectre-kde Profile Manager"
        echo "Usage: $0 [list|show <name>|import <name>|export <name>|apply <name>]"
        echo "  list    - show available profiles"
        echo "  show    - display profile info and included files"
        echo "  import  - copy profile config into scripts/ (does not apply)"
        echo "  export  - snapshot current config as a profile"
        echo "  apply   - import + quick-update"
        ;;
    *) echo "Unknown command: $1"; exit 1 ;;
esac
