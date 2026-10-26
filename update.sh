#!/usr/bin/env bash
# spectre-kde -- update.sh
# Pull latest changes from git and optionally reapply

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        spectre-kde Update Tool         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

cd "$ROOT"

# Check if it's a git repo
if [ ! -d ".git" ]; then
    echo -e "${RED}Error:${NC} Not a git repository"
    exit 1
fi

# Check for local changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}Warning:${NC} You have local uncommitted changes"
    git diff --name-only
    echo ""
    echo -n "Stash changes and continue? (y/N): "
    read -r stash_choice
    if [ "$stash_choice" = "y" ] || [ "$stash_choice" = "Y" ]; then
        git stash push -m "Auto-stash before update $(date)"
        echo -e "${GREEN}✓ Changes stashed${NC}"
    else
        echo "Update cancelled"
        exit 0
    fi
fi

echo -e "${YELLOW}Pulling latest changes...${NC}"
git pull --rebase origin main && echo -e "${GREEN}✓ Updated successfully${NC}" || {
    echo -e "${RED}Failed to pull updates${NC}"
    exit 1
}

echo ""
echo -n "Reapply configuration? (y/N): "
read -r apply_choice
if [ "$apply_choice" = "y" ] || [ "$apply_choice" = "Y" ]; then
    echo ""
    if [ -f "$ROOT/.applied-dark" ] && [ ! -f "$ROOT/.applied-light" ]; then
        echo -e "${YELLOW}Reapplying dark theme...${NC}"
        ./apply.sh --dark
    elif [ -f "$ROOT/.applied-light" ]; then
        echo -e "${YELLOW}Reapplying light theme...${NC}"
        ./apply.sh --light
    else
        echo -e "${YELLOW}No theme marker found, applying light theme...${NC}"
        ./apply.sh --light
    fi
else
    echo -e "${BLUE}Update complete. Run ./apply.sh to reapply if needed.${NC}"
fi
