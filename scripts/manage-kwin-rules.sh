#!/usr/bin/env bash
# spectre-kde -- scripts/manage-kwin-rules.sh
# Manage KWin window rules in config/applied-kwinrulesrc.conf
# The file uses KWin's native kwinrulesrc format: numeric [n] sections listed
# by [General] Order. Desktop targets use @DESKTOP_N@ placeholders resolved at
# apply time (scripts/render-kwinrules.sh), so they follow the machine.
# Usage: ./scripts/manage-kwin-rules.sh [list|add|remove|show|apply]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ROOT/config/applied-kwinrulesrc.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# next_num: highest numeric section + 1 (1 when none)
next_num() {
    awk '/^\[[0-9]+\]$/ { n = substr($0, 2, length($0) - 2) + 0; if (n > max) max = n }
         END { print max + 1 }' "$CONF"
}

# section_for <name-or-number>: resolve a rule reference to its section number.
# Accepts a numeric section directly, or a Description value.
section_for() {
    local target="$1"
    if [[ "$target" =~ ^[0-9]+$ ]] && grep -q "^\[${target}\]$" "$CONF"; then
        printf '%s\n' "$target"
        return 0
    fi
    awk -v t="$target" '
        /^\[[0-9]+\]$/ { n = substr($0, 2, length($0) - 2); next }
        /^Description=/ && n != "" && substr($0, 13) == t { print n; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$CONF"
}

# update_order: rewrite [General] Order= from the numeric sections.
update_order() {
    local rules tmp
    rules="$(awk '/^\[[0-9]+\]$/ { gsub(/[][]/, ""); printf "%s%s", sep, $0; sep = "," }' "$CONF")"
    tmp="$(mktemp)"
    awk -v rules="$rules" '
        function close_general() {
            if (in_general) {
                if (!wrote) print "Order=" rules
                in_general = 0
            }
        }
        /^\[General\]$/ { in_general = 1; print; next }
        /^\[/ { close_general(); print; next }
        {
            if (in_general && $0 ~ /^Order=/) { print "Order=" rules; wrote = 1; next }
            print
        }
        END { close_general() }
    ' "$CONF" > "$tmp" && mv "$tmp" "$CONF"
    # Fallback: if the file had no [General] section at all, add one.
    if ! grep -q '^\[General\]$' "$CONF"; then
        tmp="$(mktemp)"
        {
            echo "[General]"
            echo "Order=$rules"
            echo ""
            cat "$CONF"
        } > "$tmp" && mv "$tmp" "$CONF"
    fi
}

list_rules() {
    echo -e "${BLUE}KWin window rules (in config/applied-kwinrulesrc.conf):${NC}"
    echo "============================================================"
    if [ ! -f "$CONF" ]; then
        echo -e "${RED}Config file not found: $CONF${NC}"
        return 1
    fi
    awk '
        /^\[/ {
            if (n != "") printf "  %s. %s\n", n, (desc == "" ? "(untitled)" : desc)
            n = ""; desc = ""
            if ($0 ~ /^\[[0-9]+\]$/) n = substr($0, 2, length($0) - 2)
            next
        }
        /^Description=/ && n != "" && desc == "" { desc = substr($0, 13) }
        END { if (n != "") printf "  %s. %s\n", n, (desc == "" ? "(untitled)" : desc) }
    ' "$CONF"
    echo "============================================================"
}

show_rule() {
    local name="$1" num
    if ! num="$(section_for "$name")"; then
        echo -e "${RED}Rule not found: $name${NC}"
        return 1
    fi
    awk -v num="[$num]" '
        /^\[/ { in_rule = ($0 == num) }
        in_rule { print }
    ' "$CONF"
}

add_rule() {
    local name="$1"
    local wmclass="$2"
    local desktop="${3:-}"
    local noblord="${4:-false}"
    local keepabove="${5:-false}"

    if [ -z "$name" ] || [ -z "$wmclass" ]; then
        echo -e "${RED}Error: rule name and wmclass are required${NC}"
        echo "Usage: $0 add <name> <wmclass> [desktop] [noblord] [keepabove]"
        return 1
    fi

    if section_for "$name" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning:${NC} rule '$name' already exists"
        return 0
    fi

    local num
    num="$(next_num)"
    {
        echo ""
        echo "[${num}]"
        echo "Description=${name}"
        echo "wmclass=${wmclass}"
        echo "wmclassmatch=1"
        if [ -n "$desktop" ]; then
            echo "desktops=@DESKTOP_${desktop}@"
            echo "desktopsrule=2"
        fi
        if [ "$noblord" = "true" ]; then
            echo "decorationpolicy=none"
            echo "decorationpolicyrule=2"
        fi
        if [ "$keepabove" = "true" ]; then
            echo "above=true"
            echo "aboverule=2"
        fi
    } >> "$CONF"
    update_order

    echo -e "${GREEN}Added:${NC} $name (wmclass=$wmclass, rule [$num])"
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

remove_rule() {
    local name="$1" num

    if ! num="$(section_for "$name")"; then
        echo -e "${RED}Error:${NC} rule '$name' not found"
        return 1
    fi

    # Create backup
    cp "$CONF" "$CONF.bak"

    # Drop the target section, then renumber the rest so sections stay
    # contiguous (1..N), which keeps Order trivially consistent.
    awk -v num="$num" '
        /^\[/ {
            if ($0 == "[" num "]") { skip = 1; next }
            skip = 0
        }
        !skip { print }
    ' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"

    awk '
        /^\[[0-9]+\]$/ { new++; print "[" new "]"; next }
        { print }
    ' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"

    update_order

    echo -e "${GREEN}Removed:${NC} $name"
    echo -e "Backup saved to: $CONF.bak"
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

apply_rules() {
    echo -e "${YELLOW}Applying KWin window rules...${NC}"
    # Render @DESKTOP_N@ placeholders against this machine's kwinrc, then install.
    bash "$ROOT/scripts/render-kwinrules.sh" > "$HOME/.config/kwinrulesrc" \
        || { echo -e "${RED}Failed to render kwin rules${NC}"; return 1; }
    # Reconfigure KWin so rules take effect without logout
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null \
        || busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure 2>/dev/null \
        || echo -e "${YELLOW}Note:${NC} KWin reconfigure may need a logout/login to take effect"
    echo -e "${GREEN}✓ KWin window rules applied${NC}"
    echo -e "${BLUE}Tip:${NC} Open each app to see the rules take effect."
}

case "${1:-list}" in
    list|ls)
        list_rules
        ;;
    show)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a rule name"
            echo "Usage: $0 show <rule-name>"
            exit 1
        fi
        show_rule "$2"
        ;;
    add)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a rule name and wmclass"
            echo "Usage: $0 add <name> <wmclass> [desktop] [noblord] [keepabove]"
            echo ""
            echo "Example: $0 add 'My App' org.myapp.App 2 true false"
            exit 1
        fi
        add_rule "$2" "$3" "${4:-}" "${5:-false}" "${6:-false}"
        ;;
    remove|rm)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a rule name"
            echo "Usage: $0 remove <rule-name>"
            exit 1
        fi
        remove_rule "$2"
        ;;
    apply)
        apply_rules
        ;;
    *)
        echo -e "${BLUE}spectre-kde KWin Window Rules Manager${NC}"
        echo "=========================================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list                  - List all window rules"
        echo "  show <name>           - Show details of a rule"
        echo "  add <name> <wmclass> [desktop] [noblord] [keepabove]"
        echo "                        - Add a new window rule"
        echo "  remove <name>         - Remove a window rule"
        echo "  apply                 - Render + copy rules to ~/.config/kwinrulesrc and reconfigure KWin"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 add 'Terminal' konsole 1 true false"
        echo "  $0 add 'Music' spotify 1 false true"
        echo "  $0 remove 'Terminal'"
        echo "  $0 apply"
        echo ""
        ;;
esac
