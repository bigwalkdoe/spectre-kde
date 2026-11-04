#!/usr/bin/env bash
# Tests for scripts/manage-gtk.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/manage-gtk.sh" "$WORK/scripts/manage-gtk.sh"
chmod +x "$WORK/scripts/manage-gtk.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-gtk.sh" "$@"; }

echo "=== test-manage-gtk: status ==="
OUT="$(run status 2>&1)"
case "$OUT" in *"GTK Theme Status:"*) ok "status works" ;; *) no "status failed: $OUT" ;; esac

echo "=== test-manage-gtk: set ==="
OUT="$(run set Orchis-Dark 2>&1)"
case "$OUT" in *"GTK theme set to"*Orchis-Dark*) ok "set works" ;; *) no "set failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-gtk: ALL PASS"; exit 0; fi
echo "test-manage-gtk: $fails FAILURE(S)"
exit 1
