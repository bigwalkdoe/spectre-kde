#!/usr/bin/env bash
# spectre-kde -- scripts/preflight-check.sh
# Pre-apply validation: check all assets, tools, permissions, and config
# without making any changes.
# Usage: ./scripts/preflight-check.sh [--light|--dark]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---light}"
case "$MODE" in
  --light) LNF_PKG="com.github.vinceliuice.Orchis";       COLORS=Orchis;      ICONS=FairyWren_Light; CURSOR=Bibata-Modern-Ice ;;
  --dark)  LNF_PKG="com.github.vinceliuice.Orchis-dark"; COLORS=OrchisDark;  ICONS=FairyWren_Dark;  CURSOR=Bibata-Modern-Ice ;;
  *) echo "usage: $0 [--light|--dark]"; exit 2 ;;
esac

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ERRORS=0
WARNS=0
OKS=0

ok() { echo -e "  ${GREEN}✓${NC} $1"; ((OKS++)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; ((WARNS++)); }
err() { echo -e "  ${RED}✗${NC} $1"; ((ERRORS++)); }

echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║              spectre-kde Preflight Validation               ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Mode:${NC} $MODE"
echo ""

# --- Environment ---
echo -e "${BOLD}[Environment]${NC}"
if [ -n "${XDG_CURRENT_DESKTOP:-}" ] && [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
    ok "KDE Plasma desktop session detected ($XDG_CURRENT_DESKTOP)"
else
    warn "XDG_CURRENT_DESKTOP not set or not KDE (may not be running in Plasma)"
fi
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    ok "Display server available"
else
    err "No display server detected"
fi
echo ""

# --- Required tools ---
echo -e "${BOLD}[Required Tools]${NC}"
for tool in plasmashell kwriteconfig6 plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-lookandfeel plasma-apply-wallpaperimage gdbus busctl uuidgen flock fc-cache; do
    if command -v "$tool" >/dev/null 2>&1; then
        ok "$tool found"
    else
        err "$tool not found"
    fi
done
if command -v plasmashell >/dev/null 2>&1; then
    if plasmashell --version 2>/dev/null | grep -q '^plasmashell 6\.'; then
        ok "Plasma 6.x detected"
    else
        err "Plasma 6.x required"
    fi
fi
echo ""

# --- Theme assets ---
echo -e "${BOLD}[Theme Assets ($MODE)]${NC}"
_has(){ for d in "$HOME/.local/share/$1" "/usr/share/$1"; do [ -e "$d/$2" ] && return 0; done; return 1; }
if _has plasma/look-and-feel "$LNF_PKG"; then
    ok "Look-and-feel $LNF_PKG present"
else
    err "Look-and-feel $LNF_PKG missing"
fi
if _has color-schemes "$COLORS.colors"; then
    ok "Color scheme $COLORS present"
else
    err "Color scheme $COLORS missing"
fi
if _has icons "$ICONS"; then
    ok "Icon theme $ICONS present"
else
    err "Icon theme $ICONS missing"
fi
if _has icons "$CURSOR"; then
    ok "Cursor theme $CURSOR present"
else
    err "Cursor theme $CURSOR missing"
fi
echo ""

# --- Repository files ---
echo -e "${BOLD}[Repository Integrity]${NC}"
for f in apply.sh verify.sh scripts/layout.js scripts/dock-launchers.list scripts/tray-config.js scripts/resolve-launchers.sh scripts/restore-backup.sh; do
    if [ -f "$ROOT/$f" ]; then
        ok "$f exists"
    else
        err "$f missing"
    fi
done
if [ -x "$ROOT/apply.sh" ]; then
    ok "apply.sh is executable"
else
    warn "apply.sh not executable (will run with bash)"
fi
if [ -f "$ROOT/assets/wallpapers/wavy_lines_v02_5120x2880.png" ]; then
    ok "Vendored wallpaper present"
else
    warn "Vendored wallpaper missing (will fail on clean machine without it)"
fi
echo ""

# --- Config files ---
echo -e "${BOLD}[Configuration Files]${NC}"
for f in scripts/dock-config scripts/topbar-config config/applied-kwinrulesrc.conf config/applied-sddm.conf; do
    if [ -f "$ROOT/$f" ]; then
        ok "$f present"
    else
        warn "$f missing"
    fi
done
echo ""

# --- Disk space / permissions ---
echo -e "${BOLD}[Permissions & Space]${NC}"
if [ -w "$HOME/.config" ]; then
    ok "\$HOME/.config is writable"
else
    err "\$HOME/.config is not writable"
fi
if [ -w "$HOME/.local/share" ] || mkdir -p "$HOME/.local/share" 2>/dev/null; then
    ok "\$HOME/.local/share is writable"
else
    err "\$HOME/.local/share is not writable"
fi
free_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
if [ "${free_kb:-0}" -gt 102400 ]; then
    ok "Sufficient disk space (${free_kb}KB free)"
else
    warn "Low disk space (${free_kb}KB free)"
fi
echo ""

# --- Summary ---
echo -e "${BOLD}[Summary]${NC}"
echo -e "  ${GREEN}Passed:${NC} $OKS  ${YELLOW}Warnings:${NC} $WARNS  ${RED}Errors:${NC} $ERRORS"
echo ""
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}${BOLD}Preflight FAILED${NC} — fix errors before running apply.sh"
    exit 1
elif [ $WARNS -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}Preflight passed with warnings${NC} — apply.sh may still work"
    exit 0
else
    echo -e "${GREEN}${BOLD}Preflight PASSED${NC} — safe to run apply.sh $MODE"
    exit 0
fi
