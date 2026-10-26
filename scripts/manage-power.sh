#!/usr/bin/env bash
# spectre-kde -- scripts/manage-power.sh
# Manage power profiles and battery settings
# Usage: ./scripts/manage-power.sh [status|ac|battery|balanced|performance|powersave]

set -euo pipefail


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

status() {
    echo -e "${BLUE}Power Management Status:${NC}"
    echo "=========================="
    if [ -f "$HOME/.config/powermanagementprofilesrc" ]; then
        echo -e "${GREEN}Config:${NC} powermanagementprofilesrc exists"
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        echo -e "${BLUE}Power profile:${NC}"
        powerprofilesctl get 2>/dev/null || echo "  unknown"
        echo ""
        echo -e "${BLUE}Available profiles:${NC}"
        powerprofilesctl list 2>/dev/null || echo "  unknown"
    else
        echo -e "${YELLOW}powerprofilesctl not available${NC}"
    fi
    echo ""
    if command -v upower >/dev/null 2>&1; then
        echo -e "${BLUE}Battery:${NC}"
        upower -i "$(upower -e | grep BAT | head -1)" 2>/dev/null | grep -E "state|percentage|time to" || echo "  no battery or unknown"
    fi
    echo "=========================="
}

set_profile() {
    local profile="$1"
    if ! command -v powerprofilesctl >/dev/null 2>&1; then
        echo -e "${RED}powerprofilesctl not available${NC}"
        return 1
    fi
    echo -e "${YELLOW}Setting power profile to: $profile${NC}"
    powerprofilesctl set "$profile" && echo -e "${GREEN}✓ Power profile set to $profile${NC}" || echo -e "${RED}Failed to set profile${NC}"
}

case "${1:-status}" in
    status)
        status
        ;;
    performance)
        set_profile performance
        ;;
    balanced)
        set_profile balanced
        ;;
    powersave|power-saver|low)
        set_profile power-saver
        ;;
    ac)
        echo -e "${YELLOW}AC power settings configured in powermanagementprofilesrc${NC}"
        echo "Run ./apply.sh to restore AC-optimized settings"
        ;;
    battery)
        echo -e "${YELLOW}Battery power settings configured in powermanagementprofilesrc${NC}"
        echo "Run ./apply.sh to restore battery-optimized settings"
        ;;
    *)
        echo -e "${BLUE}spectre-kde Power Manager${NC}"
        echo "=========================="
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status       - Show power status and profiles"
        echo "  performance  - Set performance profile"
        echo "  balanced     - Set balanced profile"
        echo "  powersave    - Set power-saver profile"
        echo "  ac           - Info about AC settings"
        echo "  battery      - Info about battery settings"
        echo ""
        ;;
esac
