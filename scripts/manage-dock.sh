#!/usr/bin/env bash
# spectre-kde -- manage-dock.sh
# Manage pinned dock applications in scripts/dock-launchers.list
# Usage: ./scripts/manage-dock.sh [add|remove|list|find] [app.desktop|search-term]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIST_FILE="$ROOT/scripts/dock-launchers.list"
DESKTOP_DIRS=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "$HOME/.local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

list_dock() {
    echo -e "${BLUE}Pinned dock applications (in order):${NC}"
    echo "========================================"
    local i=1
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Extract the desktop file (before comment)
        local entry
        entry=$(echo "$line" | sed 's/[[:space:]]*#.*$//' | tr -d ' ')
        # Handle alternatives (first|second)
        local main_id
        main_id=$(echo "$entry" | cut -d'|' -f1)
        if [ -n "$main_id" ]; then
            echo -e "  ${GREEN}$i.${NC} $main_id"
            ((i++))
        fi
    done < "$LIST_FILE"
    echo "========================================"
}

find_app() {
    local search="$1"
    echo -e "${BLUE}Searching for .desktop files matching '$search':${NC}"
    echo "========================================"
    local found=0
    for dir in "${DESKTOP_DIRS[@]}"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' file; do
            local basename_file
            basename_file=$(basename "$file")
            local name
            name=$(grep -m1 "^Name=" "$file" 2>/dev/null | cut -d'=' -f2-)
            if [[ "$basename_file" =~ $search ]] || [[ "${name:-}" =~ $search ]]; then
                echo -e "  ${GREEN}ID:${NC} $basename_file"
                [ -n "${name:-}" ] && echo -e "  ${BLUE}Name:${NC} $name"
                echo -e "  ${YELLOW}Path:${NC} $file"
                echo ""
                ((found++))
            fi
        done < <(find "$dir" -name "*.desktop" -print0 2>/dev/null)
    done
    if [ $found -eq 0 ]; then
        echo -e "${RED}No applications found matching '$search'${NC}"
    fi
    echo "========================================"
}

add_app() {
    local app_id="$1"
    # Check if it's a file path or just ID
    if [ -f "$app_id" ]; then
        app_id=$(basename "$app_id")
    fi
    
    # Ensure it ends with .desktop
    [[ "$app_id" != *.desktop ]] && app_id="$app_id.desktop"
    
    # Check if already in list
    if grep -q "^[[:space:]]*$app_id" "$LIST_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Warning:${NC} $app_id is already in the dock list"
        return 0
    fi
    
    # Find the app to get its name for comment
    local app_name=""
    for dir in "${DESKTOP_DIRS[@]}"; do
        if [ -f "$dir/$app_id" ]; then
            app_name=$(grep -m1 "^Name=" "$dir/$app_id" 2>/dev/null | cut -d'=' -f2- | cut -c1-30)
            break
        fi
    done
    
    if [ -z "$app_name" ]; then
        echo -e "${YELLOW}Warning:${NC} $app_id not found in standard application directories"
        echo -e "Adding anyway... (will be skipped during apply if not installed)"
        echo "$app_id" >> "$LIST_FILE"
    else
        echo -e "${app_id}                  # ${app_name}" >> "$LIST_FILE"
        echo -e "${GREEN}Added:${NC} $app_id ($app_name)"
    fi
    
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

remove_app() {
    local app_id="$1"
    if [ -f "$app_id" ]; then
        app_id=$(basename "$app_id")
    fi
    [[ "$app_id" != *.desktop ]] && app_id="$app_id.desktop"
    
    if ! grep -q "^[[:space:]]*$app_id" "$LIST_FILE" 2>/dev/null; then
        echo -e "${RED}Error:${NC} $app_id not found in dock list"
        return 1
    fi
    
    # Create backup
    cp "$LIST_FILE" "$LIST_FILE.bak"
    
    # Remove the line (handle both with and without comments)
    sed -i "/^[[:space:]]*${app_id}[[:space:]]*\(#.*\)*$/d" "$LIST_FILE"
    
    echo -e "${GREEN}Removed:${NC} $app_id"
    echo -e "Backup saved to: $LIST_FILE.bak"
    echo -e "\n${BLUE}Run './apply.sh' to apply the changes${NC}"
}

show_config() {
    local CFG="$ROOT/dock-config"
    echo -e "${BLUE}Dock configuration:${NC}"
    echo "==================="
    if [ -f "$CFG" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            echo "  $line"
        done < "$CFG"
    else
        echo -e "${YELLOW}No dock-config file found. Using defaults.${NC}"
    fi
    echo "==================="
    echo -e "\n${BLUE}Edit scripts/dock-config to customize, then run './apply.sh'${NC}"
}

case "${1:-list}" in
    list|ls)
        list_dock
        ;;
    config|cfg)
        show_config
        ;;
    find|search)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a search term"
            echo "Usage: $0 find <search-term>"
            exit 1
        fi
        find_app "$2"
        ;;
    add)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a .desktop file or app ID"
            echo "Usage: $0 add <app.desktop|AppName>"
            exit 1
        fi
        add_app "$2"
        ;;
    remove|rm)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a .desktop file or app ID"
            echo "Usage: $0 remove <app.desktop>"
            exit 1
        fi
        remove_app "$2"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Dock Manager${NC}"
        echo "========================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list, ls          - List all pinned dock applications"
        echo "  config, cfg       - Show dock configuration"
        echo "  find <term>       - Search for installed applications"
        echo "  add <app.desktop> - Add an application to the dock"
        echo "  remove <app>      - Remove an application from the dock"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 config"
        echo "  $0 find firefox"
        echo "  $0 add org.gnome.Calculator.desktop"
        echo "  $0 remove binance.desktop"
        echo ""
        ;;
esac
