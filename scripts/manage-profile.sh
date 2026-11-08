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
            local name
            name="$(basename "$d")"
            local desc=""
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

case "${1:-list}" in
    list|ls) cmd_list ;;
    import)
        [ -n "${2:-}" ] || { echo "Usage: $0 import <name>"; exit 1; }
        bash "$ROOT/scripts/import-profile.sh" "$2"
        ;;
    export)
        [ -n "${2:-}" ] || { echo "Usage: $0 export <name>"; exit 1; }
        bash "$ROOT/scripts/export-profile.sh" "$2"
        ;;
    apply)
        [ -n "${2:-}" ] || { echo "Usage: $0 apply <name>"; exit 1; }
        bash "$ROOT/scripts/import-profile.sh" "$2"
        echo -e "${YELLOW}Applying imported profile (quick-update)...${NC}"
        bash "$ROOT/quick-update.sh"
        ;;
    help|-h|--help)
        echo "spectre-kde Profile Manager"
        echo "Usage: $0 [list|import <name>|export <name>|apply <name>]"
        echo "  list    - show available profiles"
        echo "  import  - copy profile config into scripts/ (does not apply)"
        echo "  export  - snapshot current config as a profile"
        echo "  apply   - import + quick-update"
        ;;
    *) echo "Unknown command: $1"; exit 1 ;;
esac
