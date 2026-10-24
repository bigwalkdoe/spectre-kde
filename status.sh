#!/usr/bin/env bash
# spectre-kde -- status.sh
# Quick status overview of the configuration

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════╗"
echo "║        spectre-kde Status Overview      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Theme status
echo "🎨 Theme:"
if [ -f "$ROOT/.applied-dark" ]; then
    echo "   Current: Dark (Orchis-dark)"
elif [ -f "$ROOT/.applied-light" ]; then
    echo "   Current: Light (Orchis)"
else
    if grep -q "Orchis-dark" "$HOME/.config/kdeglobals" 2>/dev/null; then
        echo "   Current: Dark (detected)"
    elif grep -q "Orchis" "$HOME/.config/kdeglobals" 2>/dev/null; then
        echo "   Current: Light (detected)"
    else
        echo "   Current: Unknown"
    fi
fi
echo ""

# Panel info
echo "📊 Panels:"
if command -v qdbus6 &> /dev/null; then
    panel_count=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "panelIds.length" 2>/dev/null | grep -o '[0-9]*' || echo "?")
    echo "   Count: $panel_count"
fi
echo ""

# Dock apps
echo "🚀 Dock Apps:"
count=$("$ROOT/scripts/manage-dock.sh" list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -cE '^[[:space:]]*[0-9]+\.' || echo 0)
echo "   Count: $count"
echo ""

# Backup info
echo "💾 Backups:"
backup_count=$(ls -1d "$HOME/.config/kde-backups/"*/ 2>/dev/null | wc -l)
echo "   Available: $backup_count"
latest=$(ls -1dt "$HOME/.config/kde-backups/"*/ 2>/dev/null | head -1)
[ -n "$latest" ] && echo "   Latest: $(basename "$latest")"
echo ""

# Quick actions
echo "⚡ Quick Actions:"
echo "   ./apply.sh --light|--dark  - Apply theme"
echo "   ./scripts/toggle-theme.sh - Toggle light/dark"
echo "   ./scripts/manage-dock.sh  - Manage dock apps"
echo "   ./scripts/manage-wallpaper.sh - Manage wallpapers"
echo "   ./verify.sh              - Full verification"
echo "   ./rollback.sh            - Rollback to last backup"
echo ""
