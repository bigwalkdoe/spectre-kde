#!/usr/bin/env bash
# spectre-kde -- scripts/manage-shortcuts.sh
# Manage/verify declared keyboard shortcuts (kglobalshortcutsrc / KGlobalAccel).
#
# SAFETY: apply.sh deliberately does NOT auto-apply shortcuts because KGlobalAccel
# owns kglobalshortcutsrc and silently drops malformed/foreign groups. This
# manager only writes when you explicitly run: manage-shortcuts.sh apply --yes
# It writes the correct KGlobalAccel triple format: current,default,description
# under the owning component group (e.g. [kwin], [plasmashell]).
#
# Usage: ./scripts/manage-shortcuts.sh [status|list|apply --yes|help]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DECL="$ROOT/scripts/shortcuts-declared.conf"
SHORTCUTS_FILE="$HOME/.config/kglobalshortcutsrc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

unescape_tabs() { printf '%s' "$1" | sed 's/\\t/\t/g'; }

read_declared() {
    [ -f "$DECL" ] || { echo -e "${RED}Missing $DECL${NC}" >&2; return 1; }
    while IFS='|' read -r comp action shortcut default desc || [ -n "${comp:-}" ]; do
        [[ "${comp:-}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${comp// }" ]] && continue
        printf '%s|%s|%s|%s|%s\n' "$comp" "$action" "$(unescape_tabs "$shortcut")" "$(unescape_tabs "$default")" "$desc"
    done < "$DECL"
}

get_live() {
    kreadconfig6 --file kglobalshortcutsrc --group "$1" --key "$2" 2>/dev/null || true
}

has_combo() {
    local got="$1" combo="$2"
    [ -n "$got" ] || { echo "no"; return; }
    printf '%s' "$got" | cut -d, -f1 | tr '\t' '\n' | grep -qxF "$combo" && echo "yes" || echo "no"
}

cmd_list() {
    echo -e "${BLUE}Declared shortcuts ($DECL):${NC}"
    read_declared | while IFS='|' read -r comp action shortcut default desc; do
        printf "  %-12s %-38s %s\n" "$comp" "$action" "${shortcut//$'\t'/ + }"
    done
}

cmd_status() {
    local ok=0 drift=0 missing=0
    echo -e "${BLUE}Shortcut status (declared vs live kglobalshortcutsrc):${NC}"
    if [ ! -f "$SHORTCUTS_FILE" ]; then
        echo -e "${RED}  $SHORTCUTS_FILE missing${NC}"
        return 1
    fi
    while IFS='|' read -r comp action shortcut default desc; do
        local live live_combo
        live="$(get_live "$comp" "$action")"
        live_combo="$(printf '%s' "$live" | cut -d, -f1)"
        # Check that every declared combo is present (declared may list alternatives joined by tab).
        local want ok_all=yes
        while IFS= read -r want; do
            [ -n "$want" ] || continue
            if [ "$(has_combo "$live" "$want")" != "yes" ]; then ok_all=no; fi
        done <<< "$(printf '%s' "$shortcut" | tr '\t' '\n')"
        if [ -z "$live" ]; then
            echo -e "  ${YELLOW}MISS${NC}  $comp / $action  (want: ${shortcut//$'\t'/+})"
            missing=$((missing+1))
        elif [ "$ok_all" = "yes" ]; then
            echo -e "  ${GREEN}OK${NC}    $comp / $action  (${live_combo//$'\t'/+})"
            ok=$((ok+1))
        else
            echo -e "  ${RED}DRIFT${NC} $comp / $action"
            echo "        want: ${shortcut//$'\t'/+}"
            echo "        live: ${live_combo//$'\t'/+}"
            drift=$((drift+1))
        fi
    done < <(read_declared)
    echo "---"
    echo "ok=$ok drift=$drift missing=$missing"
    [ "$drift" -eq 0 ] && [ "$missing" -eq 0 ]
}

cmd_apply() {
    if [ "${1:-}" != "--yes" ]; then
        echo -e "${YELLOW}Refusing to write kglobalshortcutsrc without --yes.${NC}"
        echo "apply.sh deliberately does not auto-apply shortcuts; KGlobalAccel owns this file."
        echo "Run: $0 apply --yes"
        return 1
    fi
    if [ ! -f "$SHORTCUTS_FILE" ]; then
        echo -e "${RED}$SHORTCUTS_FILE missing${NC}"; return 1
    fi
    local n=0
    while IFS='|' read -r comp action shortcut default desc; do
        # KGlobalAccel triple: current,default,description
        local triple
        triple="${shortcut},${default},${desc}"
        kwriteconfig6 --file kglobalshortcutsrc --group "$comp" --key "$action" "$triple"
        echo -e "  ${GREEN}set${NC} [$comp] $action"
        n=$((n+1))
    done < <(read_declared)
    echo "Applied $n shortcut(s). Log out/in or restart KGlobalAccel if bindings don't refresh."
}

case "${1:-status}" in
    status|st) cmd_status ;;
    list|ls) cmd_list ;;
    apply) shift; cmd_apply "${1:-}" ;;
    help|-h|--help)
        echo "spectre-kde Shortcuts Manager"
        echo "Usage: $0 [status|list|apply --yes]"
        echo "  status  - compare declared vs live (default)"
        echo "  list    - show declared shortcuts"
        echo "  apply   - write declared shortcuts (requires --yes; not run by apply.sh)"
        ;;
    *) echo "Unknown command: $1"; exit 1 ;;
esac
