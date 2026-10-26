#!/usr/bin/env bash
# spectre-kde -- install-deps.sh
# Attempt to install required dependencies

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      spectre-kde Dependency Installer  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect package manager
if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    echo -e "${GREEN}Detected:${NC} Fedora/RHEL (dnf)"
elif command -v apt >/dev/null 2>&1; then
    PKG_MGR="apt"
    echo -e "${GREEN}Detected:${NC} Debian/Ubuntu (apt)"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
    echo -e "${GREEN}Detected:${NC} Arch Linux (pacman)"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MGR="zypper"
    echo -e "${GREEN}Detected:${NC} openSUSE (zypper)"
else
    echo -e "${RED}Could not detect package manager${NC}"
    echo "Please install dependencies manually:"
    echo "  - KDE Plasma 6"
    echo "  - Orchis theme (look-and-feel, color schemes)"
    echo "  - Bibata-Modern-Ice cursor theme"
    echo "  - FairyWren icon theme"
    echo "  - qt6 tools (qdbus, kwriteconfig)"
    exit 1
fi

echo ""
echo -e "${YELLOW}Note:${NC} Some themes may need to be installed from KDE Store or manually"
echo ""

case $PKG_MGR in
    dnf)
        echo -e "${BLUE}Attempting to install available packages...${NC}"
        sudo dnf install -y \
            plasma-workspace \
            kde-cli-tools \
            qt6-qttools \
            util-linux \
            coreutils \
            2>&1 | tail -15
        echo ""
        echo -e "${YELLOW}For Orchis/Bibata/FairyWren themes, check:${NC}"
        echo "  - https://store.kde.org/"
        echo "  - Use System Settings > Get New [Themes/Cursors/Icons]"
        ;;
    apt)
        echo -e "${BLUE}Attempting to install available packages...${NC}"
        sudo apt install -y \
            plasma-workspace \
            kde-cli-tools \
            qttools5-dev-tools \
            util-linux \
            coreutils \
            2>&1 | tail -15
        echo ""
        echo -e "${YELLOW}For themes, use System Settings > Get New or download manually${NC}"
        ;;
    pacman)
        echo -e "${BLUE}Attempting to install available packages...${NC}"
        sudo pacman -S --needed \
            plasma-workspace \
            kde-cli-tools \
            qt6-tools \
            util-linux \
            coreutils \
            2>&1 | tail -15
        echo ""
        echo -e "${YELLOW}For themes, use System Settings > Get New or download from AUR${NC}"
        ;;
    zypper)
        echo -e "${BLUE}Attempting to install available packages...${NC}"
        sudo zypper install -y \
            plasma6-workspace \
            kde-cli-tools6 \
            qt6-tools \
            util-linux \
            coreutils \
            2>&1 | tail -15
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC} Run './doctor.sh' to check what's still missing."
