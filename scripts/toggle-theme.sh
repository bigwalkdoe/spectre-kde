#!/usr/bin/env bash
# spectre-kde -- toggle-theme.sh
# Quick toggle between light and dark themes
#
# Mode detection mirrors verify.sh: the Global Theme
# ([KDE] LookAndFeelPackage) is authoritative because it is what actually
# selects colors/icons/GTK. Marker files (.applied-dark/.applied-light) are
# only a fallback for when kdeglobals is unavailable.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Determine the active mode from the Global Theme actually applied.
LNF_PKG="$(kreadconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key LookAndFeelPackage 2>/dev/null || true)"

case "$LNF_PKG" in
  *Orchis-dark)
    echo "Detected dark theme, switching to light..."
    cd "$ROOT" && ./apply.sh --light
    ;;
  *Orchis|"")
    echo "Detected light theme or unknown, switching to dark..."
    cd "$ROOT" && ./apply.sh --dark
    ;;
  *)
    echo "Unknown look-and-feel '$LNF_PKG', defaulting to dark..."
    cd "$ROOT" && ./apply.sh --dark
    ;;
esac
