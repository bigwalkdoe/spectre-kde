#!/usr/bin/env bash
# spectre-kde -- menu.sh
# Interactive menu for spectre-kde management

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║                    SPECTRE-KDE MANAGER                       ║${NC}"
    echo -e "${BOLD}${CYAN}║        macOS-inspired KDE Plasma Configuration               ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_status() {
    echo -e "${BOLD}Quick Status:${NC}"
    if [ -f "$ROOT/.applied-dark" ]; then
        echo -e "  Theme: ${BLUE}Dark (Orchis-dark)${NC}"
    elif [ -f "$ROOT/.applied-light" ]; then
        echo -e "  Theme: ${YELLOW}Light (Orchis)${NC}"
    else
        echo -e "  Theme: ${RED}Not applied or unknown${NC}"
    fi
    local backup_count
    backup_count=$(ls -1d "$HOME/.config/kde-backups/"*/ 2>/dev/null | wc -l)
    echo -e "  Backups: $backup_count available"
    echo ""
}

show_menu() {
    echo -e "${BOLD}MAIN MENU${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}1)${NC} Apply Configuration"
    echo -e "${GREEN}2)${NC} Toggle Theme (Light/Dark)"
    echo -e "${GREEN}3)${NC} Status Overview"
    echo -e "${GREEN}4)${NC} Doctor (Diagnose Issues)"
    echo -e "${GREEN}5)${NC} Verify Configuration"
    echo ""
    echo -e "${CYAN}CUSTOMIZATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}6)${NC} Manage Dock Applications"
    echo -e "${GREEN}7)${NC} Manage Wallpapers"
    echo -e "${GREEN}8)${NC} Manage Autostart Apps"
    echo -e "${GREEN}9)${NC} Configure Dock Settings"
    echo -e "${GREEN}10)${NC} Configure Top Bar Settings"
    echo -e "${GREEN}11)${NC} Manage Night Color (Blue Light Filter)"
    echo -e "${GREEN}12)${NC} Quick Update (Dock/Panels/Tray)"
    echo ""
    echo -e "${YELLOW}MAINTENANCE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}13)${NC} Create Backup"
    echo -e "${GREEN}14)${NC} Rollback to Previous Backup"
    echo -e "${GREEN}15)${NC} Sync Current Config to Repo"
    echo -e "${GREEN}16)${NC} Detect Environment"
    echo -e "${GREEN}17)${NC} Export Current Config as Profile"
    echo -e "${GREEN}18)${NC} Import Configuration Profile"
    echo -e "${GREEN}19)${NC} Install Dependencies"
    echo -e "${GREEN}20)${NC} Reset/Restore Options"
    echo ""
    echo -e "${RED}0)${NC} Exit"
    echo ""
    echo -n "Enter your choice [0-20]: "
}

apply_menu() {
    echo ""
    echo -e "${BOLD}Apply Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}1)${NC} Apply Light Theme (Orchis)"
    echo -e "${GREEN}2)${NC} Apply Dark Theme (Orchis-dark)"
    echo -e "${CYAN}3)${NC} Apply Light Theme (Quick Mode)"
    echo -e "${CYAN}4)${NC} Apply Dark Theme (Quick Mode)"
    echo -e "${RED}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Enter your choice [0-4]: "
    read -r choice
    case $choice in
        1)
            echo ""
            echo -e "${YELLOW}Applying light theme...${NC}"
            cd "$ROOT" && ./apply.sh --light
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo ""
            echo -e "${YELLOW}Applying dark theme...${NC}"
            cd "$ROOT" && ./apply.sh --dark
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            echo -e "${YELLOW}Applying light theme (quick)...${NC}"
            cd "$ROOT" && ./apply.sh --light --quick
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            echo -e "${YELLOW}Applying dark theme (quick)...${NC}"
            cd "$ROOT" && ./apply.sh --dark --quick
            echo ""
            read -p "Press Enter to continue..."
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 1
            ;;
    esac
}

dock_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}DOCK MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${GREEN}1)${NC} List Pinned Apps"
        echo -e "${GREEN}2)${NC} Find/ Search Apps"
        echo -e "${GREEN}3)${NC} Add App to Dock"
        echo -e "${GREEN}4)${NC} Remove App from Dock"
        echo -e "${GREEN}5)${NC} View Dock Configuration"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-5]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-dock.sh" list
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -n "Enter search term: "
                read -r term
                echo ""
                "$ROOT/scripts/manage-dock.sh" find "$term"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -n "Enter app ID or .desktop filename: "
                read -r app
                echo ""
                "$ROOT/scripts/manage-dock.sh" add "$app"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -n "Enter app ID to remove: "
                read -r app
                echo ""
                "$ROOT/scripts/manage-dock.sh" remove "$app"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                "$ROOT/scripts/manage-dock.sh" config
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

wallpaper_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}WALLPAPER MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${GREEN}1)${NC} List Wallpapers"
        echo -e "${GREEN}2)${NC} Show Current Wallpaper"
        echo -e "${GREEN}3)${NC} Set Wallpaper"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-3]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-wallpaper.sh" list
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                "$ROOT/scripts/manage-wallpaper.sh" current
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -n "Enter wallpaper filename or path: "
                read -r wp
                echo ""
                "$ROOT/scripts/manage-wallpaper.sh" set "$wp"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

autostart_menu() {
    echo ""
    echo -e "${BOLD}AUTOSTART MANAGEMENT${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ -f "$ROOT/scripts/manage-autostart.sh" ]; then
        bash "$ROOT/scripts/manage-autostart.sh"
    else
        echo -e "${RED}Autostart manager not found${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

dock_config_menu() {
    echo ""
    echo -e "${BOLD}DOCK CONFIGURATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ -f "$ROOT/scripts/dock-config" ]; then
        cat "$ROOT/scripts/dock-config"
        echo ""
        echo -e "${YELLOW}Edit with:${NC} nano $ROOT/scripts/dock-config"
        echo -e "${YELLOW}Then run:${NC} ./apply.sh to apply changes"
    else
        echo -e "${RED}Dock config not found${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

topbar_config_menu() {
    echo ""
    echo -e "${BOLD}TOP BAR CONFIGURATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ -f "$ROOT/scripts/topbar-config" ]; then
        cat "$ROOT/scripts/topbar-config"
        echo ""
        echo -e "${YELLOW}Edit with:${NC} nano $ROOT/scripts/topbar-config"
        echo -e "${YELLOW}Then run:${NC} ./apply.sh or ./quick-update.sh to apply changes"
    else
        echo -e "${RED}Top bar config not found${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

nightlight_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}NIGHT COLOR MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        "$ROOT/scripts/manage-nightlight.sh" status
        echo ""
        echo -e "${GREEN}1)${NC} Enable Night Color (Automatic, 4500K)"
        echo -e "${GREEN}2)${NC} Enable Night Color (Timings)"
        echo -e "${GREEN}3)${NC} Disable Night Color"
        echo -e "${GREEN}4)${NC} Set Custom Schedule"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-4]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-nightlight.sh" enable Automatic 4500
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                "$ROOT/scripts/manage-nightlight.sh" enable Timings 4500
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                "$ROOT/scripts/manage-nightlight.sh" disable
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -n "Start time (HH:MM, e.g., 22:00): "
                read -r start
                echo -n "End time (HH:MM, e.g., 06:00): "
                read -r end
                echo ""
                "$ROOT/scripts/manage-nightlight.sh" schedule "$start" "$end"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main loop
while true; do
    show_header
    show_status
    show_menu
    read -r choice
    case $choice in
        1)
            apply_menu
            ;;
        2)
            echo ""
            echo -e "${YELLOW}Toggling theme...${NC}"
            "$ROOT/scripts/toggle-theme.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        3)
            echo ""
            "$ROOT/status.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            "$ROOT/doctor.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            echo ""
            "$ROOT/verify.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            dock_menu
            ;;
        7)
            wallpaper_menu
            ;;
        8)
            autostart_menu
            ;;
        9)
            dock_config_menu
            ;;
        10)
            topbar_config_menu
            ;;
        11)
            nightlight_menu
            ;;
        12)
            echo ""
            "$ROOT/quick-update.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        13)
            echo ""
            echo -e "${YELLOW}Creating backup...${NC}"
            "$ROOT/backup.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        14)
            echo ""
            echo -e "${YELLOW}Rolling back...${NC}"
            "$ROOT/rollback.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        15)
            echo ""
            echo -e "${YELLOW}Syncing current config...${NC}"
            "$ROOT/sync.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        16)
            echo ""
            "$ROOT/detect.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        17)
            echo ""
            echo -n "Enter profile name: "
            read -r pname
            echo ""
            if [ -z "$pname" ]; then
                echo -e "${RED}Profile name cannot be empty${NC}"
            else
                "$ROOT/scripts/export-profile.sh" "$pname"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;
        18)
            echo ""
            echo -e "${BOLD}Available profiles:${NC}"
            ls -1 "$ROOT/profiles/" 2>/dev/null || echo "  (none)"
            echo ""
            echo -n "Enter profile name to import: "
            read -r pname
            echo ""
            if [ -z "$pname" ]; then
                echo -e "${RED}Profile name cannot be empty${NC}"
            else
                "$ROOT/scripts/import-profile.sh" "$pname"
            fi
            echo ""
            read -p "Press Enter to continue..."
            ;;
        19)
            echo ""
            "$ROOT/install-deps.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        20)
            echo ""
            "$ROOT/reset.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        0)
            echo ""
            echo -e "${GREEN}Thanks for using spectre-kde!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 1
            ;;
    esac
done
