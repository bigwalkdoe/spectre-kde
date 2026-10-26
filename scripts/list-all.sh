#!/usr/bin/env bash
# spectre-kde -- scripts/list-all.sh
# List all scripts with descriptions

BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}All spectre-kde Scripts${NC}"
echo "========================"
echo ""

echo -e "${GREEN}Main Scripts:${NC}"
for f in menu.sh apply.sh quick-update.sh verify.sh status.sh health.sh doctor.sh detect.sh backup.sh rollback.sh sync.sh reset.sh update.sh welcome.sh commands.sh system-check.sh fix-issues.sh; do
    [ -f "$f" ] && echo "  $f"
done
echo ""

echo -e "${GREEN}Management Scripts:${NC}"
for f in scripts/manage-*.sh scripts/diff-config.sh scripts/export-config.sh scripts/export-profile.sh scripts/import-profile.sh scripts/preflight-check.sh scripts/usage-report.sh scripts/show-shortcuts.sh; do
    [ -f "$f" ] && echo "  $f"
done
echo ""
