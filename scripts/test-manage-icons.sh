#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
mkdir -p "$WORK/scripts" "$WORK/bin"
cat > "$WORK/bin/kwriteconfig6" << 'STUB'
#!/bin/sh
exit 0
STUB
chmod +x "$WORK/bin/kwriteconfig6"
export PATH="$WORK/bin:$PATH"
cp "$ROOT/scripts/manage-icons.sh" "$WORK/scripts/manage-icons.sh"
chmod +x "$WORK/scripts/manage-icons.sh"
run(){ HOME="$WORK" bash "$WORK/scripts/manage-icons.sh" "$@"; }
OUT="$(run status 2>&1)"
case "$OUT" in *"Icon Theme Status:"*) ok "status works" ;; *) no "status failed" ;; esac
if [ "$fails" -eq 0 ]; then echo "test-manage-icons: ALL PASS"; exit 0; fi
echo "test-manage-icons: $fails FAILURE(S)"; exit 1
