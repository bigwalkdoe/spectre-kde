#!/usr/bin/env bash
# Tests for scripts/manage-cursor.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/bin"
cat > "$WORK/bin/kwriteconfig6" << 'STUB'
#!/bin/sh
exit 0
STUB
chmod +x "$WORK/bin/kwriteconfig6"
export PATH="$WORK/bin:$PATH"

cp "$ROOT/scripts/manage-cursor.sh" "$WORK/scripts/manage-cursor.sh"
chmod +x "$WORK/scripts/manage-cursor.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-cursor.sh" "$@"; }

echo "=== test-manage-cursor: status ==="
OUT="$(run status 2>&1)"
case "$OUT" in *"Cursor Theme Status:"*) ok "status works" ;; *) no "status failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-cursor: ALL PASS"; exit 0; fi
echo "test-manage-cursor: $fails FAILURE(S)"
exit 1
