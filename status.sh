#!/usr/bin/env bash
# spectre-kde -- status.sh
# Quick status overview of the configuration (read-only, never writes anything)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════╗"
echo "║        spectre-kde Status Overview     ║"
echo "╚════════════════════════════════════════╝"
echo ""

# ---- theme ---------------------------------------------------------------
# Prefer the applied Global Theme over the marker files: a theme switched from
# System Settings leaves the markers alone, so the marker alone would report
# "Dark" over a light session. plasmarc [Theme] name is only the Plasma desktop
# style; when it is absent KConfig falls back to kdedefaults, which can disagree
# with the Global Theme and made this report "Light" over a dark session.
LNF_PKG="$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || true)"
PLASMA_STYLE="$(kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null || true)"
LNF_NAME="${LNF_PKG#com.github.vinceliuice.}"
echo "🎨 Theme:"
case "$LNF_PKG" in
    *-dark) echo "   Current: Dark ($LNF_NAME)" ;;
    "")     echo "   Current: Unknown (kdeglobals has no [KDE] LookAndFeelPackage)" ;;
    *)      echo "   Current: Light ($LNF_NAME)" ;;
esac
echo "   Plasma style: ${PLASMA_STYLE:-unknown}"
# The marker records which mode apply.sh last verified; it is not the same thing.
for m in light dark; do
    [ -f "$ROOT/.applied-$m" ] || continue
    echo "   Last verified apply: $m ($(date -r "$ROOT/.applied-$m" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?'))"
done
echo ""

# ---- panels --------------------------------------------------------------
# gdbus is what apply.sh uses; qdbus6 is only a fallback. Reading through
# probe-panels.js reports the same ids/height/widgets verify.sh checks, instead
# of a bare count that qdbus6 often returns empty for a live session.
echo "📊 Panels:"
if command -v gdbus >/dev/null 2>&1; then
    RAW="$(gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
        --method org.kde.PlasmaShell.evaluateScript "$(cat "$ROOT/scripts/probe-panels.js")" 2>/dev/null || true)"
    PROBE="$(printf '%s' "$RAW" | sed -e "1s/^('//" -e "\$s/',)\$//" | tr '|' '\n')"
    COUNT="$(printf '%s\n' "$PROBE" | sed -n 's/^count=//p' | tail -1)"
    echo "   Count: ${COUNT:-?}"
    printf '%s\n' "$PROBE" | grep -E '^(top|bottom);' | while IFS= read -r line; do
        loc="${line%%;*}"
        h="$(printf '%s' "$line" | sed -n 's/.*;h=\([0-9]*\).*/\1/p')"
        w="$(printf '%s' "$line" | sed -n 's/.*widgets=\([^;]*\).*/\1/p')"
        echo "   ${loc} bar: ${h:-?} px — ${w:-no widgets}"
    done
else
    echo "   (gdbus not available — cannot probe the live shell)"
fi
echo ""

# ---- dock apps -----------------------------------------------------------
echo "🚀 Dock Apps:"
count=$("$ROOT/scripts/manage-dock.sh" list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -cE '^[[:space:]]*[0-9]+\.' || echo 0)
echo "   Pinned: $count"
"$ROOT/scripts/manage-dock.sh" list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -E '^[[:space:]]*[0-9]+\.' | sed 's/^/  /' || true
echo ""

# ---- night color ---------------------------------------------------------
NC_ACTIVE="$(kreadconfig6 --file kwinrc --group NightColor --key Active 2>/dev/null || echo false)"
echo "🌙 Night Color:"
if [ "$NC_ACTIVE" = "true" ]; then
    echo "   Enabled ($(kreadconfig6 --file kwinrc --group NightColor --key Mode 2>/dev/null || echo '?') @ $(kreadconfig6 --file kwinrc --group NightColor --key NightTemperature 2>/dev/null || echo '?')K)"
else
    echo "   Disabled"
fi
echo ""

# ---- backups -------------------------------------------------------------
echo "💾 Backups:"
backup_count=$(ls -1d "$HOME/.config/kde-backups/"*/ 2>/dev/null | wc -l)
echo "   Available: $backup_count"
latest=$(ls -1dt "$HOME/.config/kde-backups/"*/ 2>/dev/null | head -1)
[ -n "$latest" ] && echo "   Latest: $(basename "$latest")"
echo ""

# ---- quick actions -------------------------------------------------------
echo "⚡ Quick Actions:"
echo "   ./menu.sh                 - Interactive manager (everything below)"
echo "   ./apply.sh --light|--dark - Apply a theme in full"
echo "   ./quick-update.sh         - Re-apply dock/top bar/tray only"
echo "   ./scripts/toggle-theme.sh - Toggle light/dark"
echo "   ./scripts/manage-dock.sh  - Manage dock apps"
echo "   ./scripts/manage-nightlight.sh - Night Color on/off/schedule"
echo "   ./verify.sh               - Full verification"
echo "   ./rollback.sh             - Rollback to last backup"
echo ""
