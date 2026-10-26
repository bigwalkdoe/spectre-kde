#!/usr/bin/env bash
# spectre-kde -- scripts/manage-fonts.sh
# Manage fonts, fontconfig exclusions, and font cache
# Usage: ./scripts/manage-fonts.sh [list|install|remove|exclude|unexclude|rebuild|info]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FONTCONFIG_DIR="$HOME/.config/fontconfig"
FONTS_CONF="$FONTCONFIG_DIR/fonts.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

list_fonts() {
    echo -e "${BLUE}Installed fonts:${NC}"
    echo "=================="
    if command -v fc-list >/dev/null 2>&1; then
        fc-list : family | sort -u | head -60
        echo ""
        echo -e "${YELLOW}... (showing first 60 families)${NC}"
        echo -e "Total families: $(fc-list : family | sort -u | wc -l)"
    else
        echo -e "${RED}fc-list not available${NC}"
    fi
    echo "=================="
}

list_installed_user() {
    echo -e "${BLUE}User-installed fonts:${NC}"
    echo "======================="
    if [ -d "$HOME/.local/share/fonts" ]; then
        find "$HOME/.local/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" -o -name "*.woff" -o -name "*.woff2" \) | while read -r f; do
            echo "  $(basename "$f")"
        done
    else
        echo -e "${YELLOW}No ~/.local/share/fonts directory${NC}"
    fi
    echo "======================="
}

show_exclusions() {
    echo -e "${BLUE}Font exclusions:${NC}"
    echo "=================="
    if [ -f "$FONTS_CONF" ]; then
        grep -A2 '<glob>' "$FONTS_CONF" 2>/dev/null | grep -v '^--$' || echo -e "${YELLOW}No exclusions configured${NC}"
    else
        echo -e "${YELLOW}No fontconfig config found${NC}"
    fi
    echo "=================="
}

rebuild_cache() {
    echo -e "${YELLOW}Rebuilding font cache...${NC}"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f -v 2>&1 | tail -5
        echo -e "${GREEN}✓ Font cache rebuilt${NC}"
    else
        echo -e "${RED}fc-cache not available${NC}"
        return 1
    fi
}

install_font() {
    local font_file="$1"
    if [ ! -f "$font_file" ]; then
        echo -e "${RED}Error:${NC} File not found: $font_file"
        return 1
    fi
    mkdir -p "$HOME/.local/share/fonts"
    cp "$font_file" "$HOME/.local/share/fonts/"
    echo -e "${GREEN}Installed:${NC} $(basename "$font_file")"
    rebuild_cache
}

exclude_font() {
    local pattern="$1"
    if [ -z "$pattern" ]; then
        echo -e "${RED}Error:${NC} Please provide a font pattern/path"
        echo "Example: $0 exclude '*/Inter/web/*'"
        return 1
    fi
    mkdir -p "$FONTCONFIG_DIR"
    if [ ! -f "$FONTS_CONF" ]; then
        cat > "$FONTS_CONF" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <selectfont>
    <rejectfont>
EOF
    else
        # Check if already has selectfont/rejectfont
        if ! grep -q '<selectfont>' "$FONTS_CONF"; then
            # Insert before </fontconfig>
            sed -i 's|</fontconfig>|  <selectfont>\n    <rejectfont>\n    </rejectfont>\n  </selectfont>\n</fontconfig>|' "$FONTS_CONF"
        elif ! grep -q '<rejectfont>' "$FONTS_CONF"; then
            sed -i 's|<selectfont>|<selectfont>\n    <rejectfont>\n    </rejectfont>|' "$FONTS_CONF"
        fi
    fi
    
    # Add exclusion if not already present
    if grep -q "<glob>$pattern</glob>" "$FONTS_CONF"; then
        echo -e "${YELLOW}Exclusion already exists:${NC} $pattern"
    else
        sed -i "/<rejectfont>/a\      <glob>$pattern</glob>" "$FONTS_CONF"
        echo -e "${GREEN}Added exclusion:${NC} $pattern"
    fi
    
    rebuild_cache
}

info_fonts() {
    echo -e "${BLUE}Font system information:${NC}"
    echo "=========================="
    echo -e "Font config dir: $FONTCONFIG_DIR"
    echo -e "User fonts dir: $HOME/.local/share/fonts"
    echo -e "System fonts: /usr/share/fonts"
    if [ -f "$FONTS_CONF" ]; then
        echo -e "fonts.conf: exists"
    else
        echo -e "fonts.conf: not found"
    fi
    if command -v fc-match >/dev/null 2>&1; then
        echo -e "Default sans: $(fc-match -s sans | head -1)"
        echo -e "Default serif: $(fc-match -s serif | head -1)"
        echo -e "Default mono: $(fc-match -s monospace | head -1)"
    fi
    echo "=========================="
}

case "${1:-list}" in
    list)
        list_fonts
        ;;
    user)
        list_installed_user
        ;;
    exclude)
        show_exclusions
        ;;
    add-exclusion|excl)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a pattern"
            echo "Usage: $0 add-exclusion '*/FontName/*'"
            exit 1
        fi
        exclude_font "$2"
        ;;
    install)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error:${NC} Please provide a font file"
            echo "Usage: $0 install /path/to/font.ttf"
            exit 1
        fi
        install_font "$2"
        ;;
    rebuild|cache)
        rebuild_cache
        ;;
    info)
        info_fonts
        ;;
    *)
        echo -e "${BLUE}spectre-kde Font Manager${NC}"
        echo "=========================="
        echo ""
        echo "Usage: $0 [command] [args]"
        echo ""
        echo "Commands:"
        echo "  list                - List installed font families"
        echo "  user                - List fonts in ~/.local/share/fonts"
        echo "  exclude             - Show current font exclusions"
        echo "  add-exclusion <pat> - Add font exclusion pattern"
        echo "  install <file>      - Install a font file"
        echo "  rebuild             - Rebuild font cache"
        echo "  info                - Show font system info"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 install ~/Downloads/Inter.ttf"
        echo "  $0 add-exclusion '*/Inter/web/*'"
        echo "  $0 rebuild"
        echo ""
        ;;
esac
