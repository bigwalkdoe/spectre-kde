#!/usr/bin/env bash
# spectre-kde -- scripts/manage-notifications.sh
# Manage Plasma notification settings per-app and global
# Usage: ./scripts/manage-notifications.sh [status|dnd|enable|disable|list-apps|set-app]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NOTIF_CONF="$HOME/.config/plasma-notifications.conf"
APPLIED_CONF="$ROOT/config/applied-plasma-notifications.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

status() {
    echo -e "${BLUE}Notification Status:${NC}"
    echo "====================="
    if [ -f "$NOTIF_CONF" ]; then
        echo -e "${GREEN}Config:${NC} $NOTIF_CONF exists"
    else
        echo -e "${YELLOW}Config:${NC} Using defaults (will be created on apply)"
    fi
    # Check Do Not Disturb
    if command -v qdbus6 >/dev/null 2>&1; then
        dnd=$(qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Get org.freedesktop.Notifications DoNotDisturb 2>/dev/null || echo "unknown")
        echo -e "Do Not Disturb: $dnd"
    fi
    echo "====================="
}

enable_dnd() {
    echo -e "${YELLOW}Enabling Do Not Disturb...${NC}"
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Set org.freedesktop.Notifications DoNotDisturb true 2>/dev/null && \
            echo -e "${GREEN}✓ Do Not Disturb enabled${NC}" || \
            echo -e "${YELLOW}Note:${NC} DND may need to be set via System Settings"
    else
        echo -e "${YELLOW}Note:${NC} qdbus6 not available, use System Settings"
    fi
}

disable_dnd() {
    echo -e "${YELLOW}Disabling Do Not Disturb...${NC}"
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Set org.freedesktop.Notifications DoNotDisturb false 2>/dev/null && \
            echo -e "${GREEN}✓ Do Not Disturb disabled${NC}" || \
            echo -e "${YELLOW}Note:${NC} DND may need to be set via System Settings"
    else
        echo -e "${YELLOW}Note:${NC} qdbus6 not available"
    fi
}

list_apps() {
    echo -e "${BLUE}Apps with notification settings:${NC}"
    echo "=================================="
    if [ -f "$NOTIF_CONF" ]; then
        grep -n "^\[Applications\]\[.*\]" "$NOTIF_CONF" 2>/dev/null | sed 's/\[Applications\]\[//g; s/\]//g' || echo -e "${YELLOW}No per-app settings configured${NC}"
    else
        echo -e "${YELLOW}No notification config found${NC}"
    fi
    echo "=================================="
}

reset_defaults() {
    echo -e "${YELLOW}Restoring default notification settings...${NC}"
    mkdir -p "$HOME/.config"
    cp "$APPLIED_CONF" "$NOTIF_CONF" && echo -e "${GREEN}✓ Defaults restored${NC}" || echo -e "${RED}Failed to restore defaults${NC}"
}

case "${1:-status}" in
    status)
        status
        ;;
    dnd|donotdisturb)
        case "${2:-on}" in
            on|enable|true)
                enable_dnd
                ;;
            off|disable|false)
                disable_dnd
                ;;
            *)
                status
                ;;
        esac
        ;;
    enable-dnd)
        enable_dnd
        ;;
    disable-dnd)
        disable_dnd
        ;;
    list|list-apps)
        list_apps
        ;;
    reset)
        reset_defaults
        ;;
    *)
        echo -e "${BLUE}spectre-kde Notification Manager${NC}"
        echo "=================================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  status                - Show notification status"
        echo "  dnd on|off            - Toggle Do Not Disturb"
        echo "  enable-dnd            - Enable Do Not Disturb"
        echo "  disable-dnd           - Disable Do Not Disturb"
        echo "  list-apps             - List apps with custom notification settings"
        echo "  reset                 - Restore default notification settings"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 dnd on"
        echo "  $0 reset"
        echo ""
        ;;
esac
