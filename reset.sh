#!/usr/bin/env bash
# spectre-kde -- reset.sh
# Reset configuration to defaults or clean state

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        spectre-kde Reset Tool          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Warning:${NC} This will reset configurations to defaults."
echo "A backup will be created before making changes."
echo ""
echo "Options:"
echo "  1) Reset dock to default"
echo "  2) Reset top bar to default"
echo "  3) Reset all custom configs"
echo "  4) Remove all backups (keep current)"
echo "  0) Cancel"
echo ""
echo -n "Enter choice [0-4]: "
read -r choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Resetting dock configuration...${NC}"
        cp "$ROOT/scripts/dock-launchers.list" "$ROOT/scripts/dock-launchers.list.bak.$(date +%s)" 2>/dev/null || true
        # Reset to original from git if possible
        if git -C "$ROOT" show HEAD:scripts/dock-launchers.list > /dev/null 2>&1; then
            git -C "$ROOT" show HEAD:scripts/dock-launchers.list > "$ROOT/scripts/dock-launchers.list"
            echo -e "${GREEN}✓ Dock launchers reset to default${NC}"
        else
            echo -e "${RED}Could not reset dock launchers${NC}"
        fi
        cp "$ROOT/scripts/dock-config" "$ROOT/scripts/dock-config.bak.$(date +%s)" 2>/dev/null || true
        if git -C "$ROOT" show HEAD:scripts/dock-config > /dev/null 2>&1; then
            git -C "$ROOT" show HEAD:scripts/dock-config > "$ROOT/scripts/dock-config"
            echo -e "${GREEN}✓ Dock config reset to default${NC}"
        fi
        echo ""
        echo "Run './quick-update.sh' or './apply.sh' to apply"
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Resetting top bar configuration...${NC}"
        cp "$ROOT/scripts/topbar-config" "$ROOT/scripts/topbar-config.bak.$(date +%s)" 2>/dev/null || true
        cat > "$ROOT/scripts/topbar-config" << 'EOF'
# spectre-kde top bar configuration
# Customize top bar appearance and widgets

# Top bar height multiplier (grid units)
TOPBAR_HEIGHT_MULTIPLIER=10/6

# Show global menu (true/false)
TOPBAR_SHOW_APP_MENU=true

# Show workspace pager (true/false)
TOPBAR_SHOW_PAGER=true

# Show system tray (true/false)
TOPBAR_SHOW_TRAY=true

# Show digital clock (true/false)
TOPBAR_SHOW_CLOCK=true
EOF
        echo -e "${GREEN}✓ Top bar config reset to default${NC}"
        echo ""
        echo "Run './quick-update.sh' or './apply.sh' to apply"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Creating backup first...${NC}"
        BACKUP=$("$ROOT/backup.sh" 2>&1 | grep '^BackUp=' | cut -d= -f2-)
        echo -e "${GREEN}Backup created: $BACKUP${NC}"
        echo ""
        echo -e "${YELLOW}Resetting all custom configs...${NC}"
        # Reset to defaults from repo
        [ -f "$ROOT/scripts/dock-launchers.list" ] && cp "$ROOT/scripts/dock-launchers.list" "$ROOT/scripts/dock-launchers.list.bak"
        [ -f "$ROOT/scripts/dock-config" ] && cp "$ROOT/scripts/dock-config" "$ROOT/scripts/dock-config.bak"
        [ -f "$ROOT/scripts/topbar-config" ] && cp "$ROOT/scripts/topbar-config" "$ROOT/scripts/topbar-config.bak"
        git -C "$ROOT" checkout -- scripts/dock-launchers.list scripts/dock-config 2>/dev/null || true
        # Reset topbar
        cat > "$ROOT/scripts/topbar-config" << 'EOF'
# spectre-kde top bar configuration
# Customize top bar appearance and widgets

# Top bar height multiplier (grid units)
TOPBAR_HEIGHT_MULTIPLIER=10/6

# Show global menu (true/false)
TOPBAR_SHOW_APP_MENU=true

# Show workspace pager (true/false)
TOPBAR_SHOW_PAGER=true

# Show system tray (true/false)
TOPBAR_SHOW_TRAY=true

# Show digital clock (true/false)
TOPBAR_SHOW_CLOCK=true
EOF
        echo -e "${GREEN}✓ Configs reset${NC}"
        echo ""
        echo "Run './apply.sh --light' or './apply.sh --dark' to reapply"
        ;;
    4)
        echo ""
        echo -e "${RED}This will delete all backups in ~/.config/kde-backups/${NC}"
        echo -n "Are you sure? (yes/no): "
        read -r confirm
        if [ "$confirm" = "yes" ]; then
            rm -rf "$HOME/.config/kde-backups/"*
            echo -e "${GREEN}✓ Backups removed${NC}"
        else
            echo "Cancelled"
        fi
        ;;
    0)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
echo ""
read -p "Press Enter to continue..."
