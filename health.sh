#!/usr/bin/env bash
# shellcheck disable=SC2034
# shellcheck disable=SC2034,SC1090,SC2046
# spectre-kde -- health.sh
# Comprehensive system health dashboard

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                    SPECTRE-KDE HEALTH DASHBOARD                   ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}Generated: $(date)${NC}"
echo ""

# System Info
echo -e "${BOLD}[System]${NC}"
echo -e "  Hostname: $(hostname)"
echo -e "  User: $USER"
echo -e "  Kernel: $(uname -r)"
echo -e "  Desktop: ${XDG_CURRENT_DESKTOP:-unknown} / ${XDG_SESSION_TYPE:-unknown}"
echo ""

# Theme
echo -e "${BOLD}[Theme]${NC}"
echo -e "  Global Theme: $(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || echo 'unknown')"
echo -e "  Plasma Style: $(kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null || echo 'unknown')"
echo -e "  Colors: $(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || echo 'unknown')"
echo -e "  Icons: $(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null || echo 'unknown')"
echo -e "  Cursor: $(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || echo 'unknown')"
echo ""

# Panels
echo -e "${BOLD}[Panels & Dock]${NC}"
if command -v gdbus >/dev/null 2>&1; then
    RAW="$(gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "$(cat "$ROOT/scripts/probe-panels.js")" 2>/dev/null || true)"
    PROBE="$(printf '%s' "$RAW" | sed -e "1s/^('//" -e "\$s/',)\$//" | tr '|' '\n')"
    printf '%s\n' "$PROBE" | grep -E '^(top|bottom);' | while IFS= read -r line; do
        loc="${line%%;*}"
        h="$(printf '%s' "$line" | sed -n 's/.*;h=\([0-9]*\).*/\1/p')"
        echo -e "  ${loc}: ${h}px"
    done
fi
echo ""

# Power
echo -e "${BOLD}[Power]${NC}"
if command -v powerprofilesctl >/dev/null 2>&1; then
    echo -e "  Profile: $(powerprofilesctl get 2>/dev/null || echo 'unknown')"
fi
if command -v upower >/dev/null 2>&1; then
    BAT=$(upower -e 2>/dev/null | grep BAT | head -1)
    if [ -n "$BAT" ]; then
        PCT=$(upower -i "$BAT" 2>/dev/null | grep percentage | awk '{print $2}')
        echo -e "  Battery: ${PCT:-unknown}"
    else
        echo -e "  Battery: AC power"
    fi
fi
echo ""

# Resources
echo -e "${BOLD}[Resources]${NC}"
echo -e "  Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2 " (" $7 " available)"}')"
echo -e "  Disk (/): $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo -e "  Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Backups
echo -e "${BOLD}[Backups]${NC}"
BK_COUNT=$(ls -1d "$HOME/.config/kde-backups/"*/ 2>/dev/null | wc -l)
echo -e "  Count: $BK_COUNT"
if [ "$BK_COUNT" -gt 0 ]; then
    echo -e "  Latest: $(basename "$(ls -1dt "$HOME/.config/kde-backups/"*/ 2>/dev/null | head -1)")"
fi
echo ""

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "Run ${BOLD}./doctor.sh${NC} for diagnostics or ${BOLD}./verify.sh${NC} for full verification"
echo ""
