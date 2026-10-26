#!/usr/bin/env bash
# spectre-kde -- scripts/diff-config.sh
# Compare live config with repo's config/ snapshots
# Usage: ./scripts/diff-config.sh [file]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$HOME/.config"
REPO_CFG="$ROOT/config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FILES=(
    plasma-org.kde.plasma.desktop-appletsrc
    plasmashellrc
    kdeglobals
    kwinrc
    kglobalshortcutsrc
    kcminputrc
    ksplashrc
    plasmarc
    kwinrulesrc
)

diff_file() {
    local f="$1"
    echo -e "${BLUE}=== $f ===${NC}"
    if [ ! -f "$CFG/$f" ] && [ ! -f "$REPO_CFG/applied-${f//rc/.rc}.conf" ] && [ ! -f "$REPO_CFG/applied-${f}.conf" ]; then
        echo -e "${YELLOW}(file not found in either location)${NC}"
        echo ""
        return
    fi
    
    # Try to find matching repo file
    local repo_file=""
    if [ -f "$REPO_CFG/applied-$f.conf" ]; then
        repo_file="$REPO_CFG/applied-$f.conf"
    elif [ -f "$REPO_CFG/applied-$(basename "$f" .rc)rc.conf" ]; then
        repo_file="$REPO_CFG/applied-$(basename "$f" .rc)rc.conf"
    elif [ -f "$REPO_CFG/$f" ]; then
        repo_file="$REPO_CFG/$f"
    fi
    
    if [ -n "$repo_file" ] && [ -f "$CFG/$f" ]; then
        if diff -q "$repo_file" "$CFG/$f" >/dev/null 2>&1; then
            echo -e "${GREEN}Identical${NC}"
        else
            echo -e "${YELLOW}Different${NC}"
            diff -u "$repo_file" "$CFG/$f" | head -40
            echo -e "${YELLOW}... (use 'diff -u $repo_file $CFG/$f' for full diff)${NC}"
        fi
    elif [ -f "$CFG/$f" ] && [ -z "$repo_file" ]; then
        echo -e "${BLUE}Live file exists (no repo snapshot)${NC}"
    elif [ -f "$repo_file" ] && [ ! -f "$CFG/$f" ]; then
        echo -e "${RED}Live file missing (repo has snapshot)${NC}"
    fi
    echo ""
}

if [ $# -gt 0 ]; then
    diff_file "$1"
else
    echo -e "${BLUE}spectre-kde Config Diff (live vs repo snapshots)${NC}"
    echo "===================================================="
    echo ""
    for f in "${FILES[@]}"; do
        diff_file "$f"
    done
    echo -e "${BLUE}====================================================${NC}"
    echo -e "Run with a filename to see full diff for one file"
fi
