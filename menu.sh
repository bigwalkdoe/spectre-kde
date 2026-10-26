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
    echo -e "${GREEN}6)${NC} Preflight Check (Validate Before Apply)"
    echo ""
    echo -e "${CYAN}CUSTOMIZATION${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}7)${NC} Manage Dock Applications"
    echo -e "${GREEN}8)${NC} Manage Wallpapers"
    echo -e "${GREEN}9)${NC} Manage Autostart Apps"
    echo -e "${GREEN}10)${NC} Configure Dock Settings"
    echo -e "${GREEN}11)${NC} Configure Top Bar Settings"
    echo -e "${GREEN}12)${NC} Manage KWin Window Rules"
    echo -e "${GREEN}13)${NC} Manage Night Color (Blue Light Filter)"
    echo -e "${GREEN}14)${NC} Manage Fonts"
    echo -e "${GREEN}15)${NC} Manage Notifications"
    echo -e "${GREEN}16)${NC} Quick Update (Dock/Panels/Tray)"
    echo ""
    echo -e "${YELLOW}MAINTENANCE${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}17)${NC} Create Backup"
    echo -e "${GREEN}18)${NC} Rollback to Previous Backup"
    echo -e "${GREEN}19)${NC} Sync Current Config to Repo"
    echo -e "${GREEN}20)${NC} Detect Environment"
    echo -e "${GREEN}21)${NC} Export Current Config as Profile"
    echo -e "${GREEN}22)${NC} Import Configuration Profile"
    echo -e "${GREEN}23)${NC} Install Dependencies"
    echo -e "${GREEN}24)${NC} Reset/Restore Options"
    echo ""
    echo -e "${RED}0)${NC} Exit"
    echo ""
    echo -n "Enter your choice [0-24]: "
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

fonts_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}FONT MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${GREEN}1)${NC} List installed fonts"
        echo -e "${GREEN}2)${NC} List user fonts (~/.local/share/fonts)"
        echo -e "${GREEN}3)${NC} Show font exclusions"
        echo -e "${GREEN}4)${NC} Add font exclusion"
        echo -e "${GREEN}5)${NC} Install font file"
        echo -e "${GREEN}6)${NC} Rebuild font cache"
        echo -e "${GREEN}7)${NC} Font system info"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-7]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-fonts.sh" list
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                "$ROOT/scripts/manage-fonts.sh" user
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                "$ROOT/scripts/manage-fonts.sh" exclude
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -n "Exclusion pattern (e.g., '*/Inter/web/*'): "
                read -r pattern
                echo ""
                if [ -z "$pattern" ]; then
                    echo -e "${RED}Pattern cannot be empty${NC}"
                else
                    "$ROOT/scripts/manage-fonts.sh" add-exclusion "$pattern"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                echo -n "Font file path: "
                read -r fontfile
                echo ""
                if [ -z "$fontfile" ]; then
                    echo -e "${RED}File path cannot be empty${NC}"
                else
                    "$ROOT/scripts/manage-fonts.sh" install "$fontfile"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                "$ROOT/scripts/manage-fonts.sh" rebuild
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                echo ""
                "$ROOT/scripts/manage-fonts.sh" info
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

notifications_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}NOTIFICATION MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${GREEN}1)${NC} Show notification status"
        echo -e "${GREEN}2)${NC} Enable Do Not Disturb"
        echo -e "${GREEN}3)${NC} Disable Do Not Disturb"
        echo -e "${GREEN}4)${NC} List apps with custom notification settings"
        echo -e "${GREEN}5)${NC} Restore default notification settings"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-5]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-notifications.sh" status
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                "$ROOT/scripts/manage-notifications.sh" enable-dnd
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                "$ROOT/scripts/manage-notifications.sh" disable-dnd
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                "$ROOT/scripts/manage-notifications.sh" list-apps
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                "$ROOT/scripts/manage-notifications.sh" reset
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

kwin_rules_menu() {
    while true; do
        show_header
        show_status
        echo -e "${BOLD}KWIN WINDOW RULES MANAGEMENT${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        "$ROOT/scripts/manage-kwin-rules.sh" list
        echo ""
        echo -e "${GREEN}1)${NC} List all rules"
        echo -e "${GREEN}2)${NC} Show rule details"
        echo -e "${GREEN}3)${NC} Add a new rule"
        echo -e "${GREEN}4)${NC} Remove a rule"
        echo -e "${GREEN}5)${NC} Apply rules to KWin (copy + reconfigure)"
        echo -e "${RED}0)${NC} Back to Main Menu"
        echo ""
        echo -n "Enter your choice [0-5]: "
        read -r choice
        case $choice in
            1)
                echo ""
                "$ROOT/scripts/manage-kwin-rules.sh" list
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo -n "Enter rule name: "
                read -r rname
                echo ""
                if [ -z "$rname" ]; then
                    echo -e "${RED}Rule name cannot be empty${NC}"
                else
                    "$ROOT/scripts/manage-kwin-rules.sh" show "$rname"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo -n "Rule name (e.g., 'My App'): "
                read -r rname
                echo -n "Window class (e.g., org.myapp.App): "
                read -r wmclass
                echo -n "Desktop number (optional, press Enter to skip): "
                read -r rdesktop
                echo -n "Borderless? (true/false, default false): "
                read -r rnoblord
                echo -n "Keep above? (true/false, default false): "
                read -r rkeepabove
                echo ""
                [ -z "$rnoblord" ] && rnoblord="false"
                [ -z "$rkeepabove" ] && rkeepabove="false"
                "$ROOT/scripts/manage-kwin-rules.sh" add "$rname" "$wmclass" "$rdesktop" "$rnoblord" "$rkeepabove"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -n "Rule name to remove: "
                read -r rname
                echo ""
                if [ -z "$rname" ]; then
                    echo -e "${RED}Rule name cannot be empty${NC}"
                else
                    "$ROOT/scripts/manage-kwin-rules.sh" remove "$rname"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                "$ROOT/scripts/manage-kwin-rules.sh" apply
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
            echo ""
            echo -e "${YELLOW}Running preflight check...${NC}"
            "$ROOT/scripts/preflight-check.sh" --light
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            dock_menu
            ;;
        8)
            wallpaper_menu
            ;;
        9)
            autostart_menu
            ;;
        10)
            dock_config_menu
            ;;
        11)
            topbar_config_menu
            ;;
        12)
            kwin_rules_menu
            ;;
        13)
            nightlight_menu
            ;;
        14)
            fonts_menu
            ;;
        15)
            notifications_menu
            ;;
        16)
            echo ""
            "$ROOT/quick-update.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        17)
            echo ""
            echo -e "${YELLOW}Creating backup...${NC}"
            "$ROOT/backup.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        18)
            echo ""
            echo -e "${YELLOW}Rolling back...${NC}"
            "$ROOT/rollback.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        19)
            echo ""
            echo -e "${YELLOW}Syncing current config...${NC}"
            "$ROOT/sync.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        20)
            echo ""
            "$ROOT/detect.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        21)
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
        22)
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
        23)
            echo ""
            "$ROOT/install-deps.sh"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        24)
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
