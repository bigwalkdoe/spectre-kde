#!/usr/bin/env bash
# spectre-kde -- system-check.sh
# Run all checks: doctor, preflight, verify

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                      SPECTRE-KDE SYSTEM CHECK                     ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BOLD}[1/3] Running Doctor...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$ROOT/doctor.sh" 2>&1 | tail -30
echo ""

echo -e "${BOLD}[2/3] Running Preflight Check...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$ROOT/scripts/preflight-check.sh" --light 2>&1 | tail -15
echo ""
"$ROOT/scripts/preflight-check.sh" --dark 2>&1 | tail -15
echo ""

echo -e "${BOLD}[3/3] Running Verification...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$ROOT/verify.sh" --no-health 2>&1 | tail -20
echo ""

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}System check complete!${NC}"
echo ""
