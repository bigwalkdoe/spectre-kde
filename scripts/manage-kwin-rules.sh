#!/usr/bin/env bash
# spectre-kde -- scripts/manage-kwin-rules.sh
# Manage declarative KWin window rules in config/applied-kwinrulesrc.conf
# Usage: ./scripts/manage-kwin-rules.sh [list|add|remove|show|apply]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ROOT/config/applied-kwinrulesrc.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

list_rules() {
    echo -e "${BLUE}KWin window rules (in config/applied-kwinrulesrc.conf):${NC}"
    echo "============================================================"
    if [ ! -f "$CONF" ]; then
        echo -e "${RED}Config file not found: $CONF${NC}"
        return 1
    fi
    local i=1
    local in_rule=0
    local rule_name=""
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip blank lines and comments outside rule sections
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        # Detect rule section header
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            rule_name="${BASH_REMATCH[1]}"
            in_rule=1
            echo -e "  ${GREEN}$i.${NC} $rule_name"
            ((i++))
            continue
        fi
        # Show key=value lines within a rule
        if [ "$in_rule" -eq 1 ] && [[ "$line" =~ ^[a-zA-Z_]+= ]]; then
            local key="${line%%=*}"
            local val="${line#*=}"
            echo -e "      ${BLUE}${key}${NC}=${val}"
        fi
    done < "$CONF"
    echo "============================================================"
}

show_rule() {
    local name="$1"
    local found=0
    local in_rule=0
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            if [ "${BASH_REMATCH[1]}" = "$name" ]; then
                in_rule=1
                found=1
                echo -e "${BLUE}[$name]${NC}"
                continue
            else
                in_rule=0
                continue
            fi
        fi
        if [ "$in_rule" -eq 1 ]; then
            # Stop at next section or non-key line
            if [[ "$line" =~ ^\[ ]]; then
                break
            fi
            if [[ "$line" =~ ^[a-zA-Z_]+= ]] || [[ -z "${line// }" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                echo "$line"
            fi
        fi
    done < "$CONF"
    if [ "$found" -eq 0 ]; then
        echo -e "${RED}Rule not found: $name${NC}"
        return 1
    fi
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

    # Check if rule already exists
    if grep -q "^\[${name}\]" "$CONF" 2>/dev/null; then
        echo -e "${YELLOW}Warning:${NC} rule '$name' already exists"
        return 0
    fi

    # Append the new rule
    {
        echo ""
        echo "# Added by manage-kwin-rules.sh on $(date)"
        echo "[${name}]"
        echo "wmclass=${wmclass}"
        if [ -n "$desktop" ]; then
            echo "desktop=${desktop}"
        fi
        echo "noblord=${noblord}"
        echo "keepabove=${keepabove}"
        echo "description=${name}"
    } >> "$CONF"

    echo -e "${GREEN}Added:${NC} $name (wmclass=$wmclass)"
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

remove_rule() {
    local name="$1"

    if ! grep -q "^\[${name}\]" "$CONF" 2>/dev/null; then
        echo -e "${RED}Error:${NC} rule '$name' not found"
        return 1
    fi

    # Create backup
    cp "$CONF" "$CONF.bak"

    # Remove the rule section: from the [name] line to the next [ or EOF
    awk -v name="$name" '
        BEGIN { skip=0 }
        /^\[/ {
            if ($0 == "[" name "]") { skip=1; next }
            skip=0
        }
        !skip { print }
    ' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"

    echo -e "${GREEN}Removed:${NC} $name"
    echo -e "Backup saved to: $CONF.bak"
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

apply_rules() {
    echo -e "${YELLOW}Applying KWin window rules...${NC}"
    cp "$CONF" "$HOME/.config/kwinrulesrc" \
        || { echo -e "${RED}Failed to copy kwin rules${NC}"; return 1; }
    # Reconfigure KWin so rules take effect without logout
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null \
        || busctl --user call org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null \
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
        echo "  apply                 - Copy rules to ~/.config/kwinrulesrc and reconfigure KWin"
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
