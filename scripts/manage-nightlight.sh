#!/usr/bin/env bash
# spectre-kde -- manage-nightlight.sh
# Manage Night Color (blue light filter) settings

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_status() {
    echo -e "${BLUE}Night Color Status:${NC}"
    echo "===================="
    local enabled mode temp
    enabled=$(kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo "false")
    mode=$(kreadconfig6 --file kwinrc --group NightColor --key Mode 2>/dev/null || echo "Unknown")
    temp=$(kreadconfig6 --file kwinrc --group NightColor --key NightTemperature 2>/dev/null || echo "Unknown")
    echo -e "  Enabled: $enabled"
    echo -e "  Mode: $mode"
    echo -e "  Night Temperature: $temp (K)"
    echo "===================="
}

enable_nightlight() {
    local mode="${1:-Automatic}" # Automatic, Location, Timings, Constant
    local temp="${2:-4500}"
    
    echo -e "${YELLOW}Enabling Night Color...${NC}"
    kwriteconfig6 --file kwinrc --group NightColor --key Active true
    kwriteconfig6 --file kwinrc --group NightColor --key Mode "$mode"
    kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature "$temp"
    
    # Apply changes
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    
    echo -e "${GREEN}✓ Night Color enabled${NC}"
    show_status
}

disable_nightlight() {
    echo -e "${YELLOW}Disabling Night Color...${NC}"
    kwriteconfig6 --file kwinrc --group NightColor --key Active false
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    echo -e "${GREEN}✓ Night Color disabled${NC}"
    show_status
}

set_schedule() {
    local start="${1:-22:00}"
    local end="${2:-06:00}"
    echo -e "${YELLOW}Setting schedule...${NC}"
    kwriteconfig6 --file kwinrc --group NightColor --key Mode Timings
    kwriteconfig6 --file kwinrc --group NightColor --key EveningBeginFixed "$start"
    kwriteconfig6 --file kwinrc --group NightColor --key MorningBeginFixed "$end"
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    echo -e "${GREEN}✓ Schedule set ($start - $end)${NC}"
    show_status
}

case "${1:-status}" in
    status)
        show_status
        ;;
    enable)
        enable_nightlight "${2:-Automatic}" "${3:-4500}"
        ;;
    disable)
        disable_nightlight
        ;;
    schedule)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            echo "Usage: $0 schedule <start> <end> (e.g., 22:00 06:00)"
            exit 1
        fi
        set_schedule "$2" "$3"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Night Color Manager${NC}"
        echo "=================================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  status              - Show current status"
        echo "  enable [mode] [temp] - Enable night color (mode: Automatic/Location/Timings/Constant, temp in K)"
        echo "  disable             - Disable night color"
        echo "  schedule <start> <end> - Set fixed schedule (HH:MM format)"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 enable Automatic 4500"
        echo "  $0 schedule 22:00 06:00"
        echo "  $0 disable"
        echo ""
        ;;
esac
