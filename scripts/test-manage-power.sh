#!/usr/bin/env bash
# Tests for scripts/manage-power.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/manage-power.sh" "$WORK/scripts/manage-power.sh"
chmod +x "$WORK/scripts/manage-power.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-power.sh" "$@"; }

echo "=== test-manage-power: status ==="
OUT="$(run status 2>&1)"
case "$OUT" in *"Power Management Status:"*) ok "status works" ;; *) no "status failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-power: ALL PASS"; exit 0; fi
echo "test-manage-power: $fails FAILURE(S)"
exit 1
