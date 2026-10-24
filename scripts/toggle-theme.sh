#!/usr/bin/env bash
# spectre-kde -- toggle-theme.sh
# Quick toggle between light and dark themes

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Check current theme
if [ -f "$ROOT/.applied-dark" ] && [ ! -f "$ROOT/.applied-light" ]; then
    echo "Currently dark, switching to light..."
    cd "$ROOT" && ./apply.sh --light
elif [ -f "$ROOT/.applied-light" ] && [ ! -f "$ROOT/.applied-dark" ]; then
    echo "Currently light, switching to dark..."
    cd "$ROOT" && ./apply.sh --dark
elif [ -f "$ROOT/.applied-light" ] && [ -f "$ROOT/.applied-dark" ]; then
    # Both exist, check which is newer
    if [ "$ROOT/.applied-dark" -nt "$ROOT/.applied-light" ]; then
        echo "Currently dark, switching to light..."
        cd "$ROOT" && ./apply.sh --light
    else
        echo "Currently light, switching to dark..."
        cd "$ROOT" && ./apply.sh --dark
    fi
else
    # No marker, detect from kdeglobals
    if grep -q "Orchis-dark" "$HOME/.config/kdeglobals" 2>/dev/null; then
        echo "Detected dark theme, switching to light..."
        cd "$ROOT" && ./apply.sh --light
    else
        echo "Detected light theme or unknown, switching to dark..."
        cd "$ROOT" && ./apply.sh --dark
    fi
fi
