#!/usr/bin/env bash
# spectre-kde -- scripts/clean-backups.sh
# Clean old backups, keep only the N most recent
# Usage: ./scripts/clean-backups.sh [keep_count]

set -euo pipefail

BACKUP_DIR="$HOME/.config/kde-backups"
KEEP="${1:-10}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}No backups directory found${NC}"
    exit 0
fi

count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo -e "${BLUE}Current backups:${NC} $count"
echo -e "${BLUE}Keeping most recent:${NC} $KEEP"

if [ "$count" -le "$KEEP" ]; then
    echo -e "${GREEN}Nothing to clean${NC}"
    exit 0
fi

to_remove=$((count - KEEP))
echo -e "${YELLOW}Removing $to_remove old backup(s)...${NC}"

# Sort by modification time (oldest first) and remove
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -n | head -n "$to_remove" | cut -d' ' -f2- | while read -r d; do
    echo -e "  Removing: $(basename "$d")"
    rm -rf "$d"
done

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo -e "${BLUE}Remaining backups:${NC} $(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)"
