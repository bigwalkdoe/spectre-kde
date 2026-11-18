#!/usr/bin/env bash
# Tests for scripts/manage-autostart.sh (guards only; no live session needed).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/.config/autostart"
# seed a pre-existing autostart entry to ensure guard doesn't delete it
echo "dummy" > "$WORK/.config/autostart/someapp.desktop"
cp "$ROOT/scripts/manage-autostart.sh" "$WORK/scripts/manage-autostart.sh"
chmod +x "$WORK/scripts/manage-autostart.sh"

# Empty list file
: > "$WORK/scripts/autostart.list"
echo "=== test-manage-autostart: empty list guard ==="
OUT="$(HOME="$WORK" bash "$WORK/scripts/manage-autostart.sh" 2>&1)" || true
if [ -f "$WORK/.config/autostart/someapp.desktop" ]; then
    ok "empty list did not wipe autostart dir"
else
    no "empty list wiped autostart dir"
fi
case "$OUT" in *"no entries"*) ok "empty list reported no entries" ;; *) no "empty list message missing: $OUT" ;; esac

# List with only unresolvable entries
printf 'nonexistent-app.desktop\n' > "$WORK/scripts/autostart.list"
echo "=== test-manage-autostart: unresolved guard ==="
OUT="$(HOME="$WORK" bash "$WORK/scripts/manage-autostart.sh" 2>&1)" || true
if [ -f "$WORK/.config/autostart/someapp.desktop" ]; then
    ok "unresolved list did not wipe autostart dir"
else
    no "unresolved list wiped autostart dir"
fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-autostart: ALL PASS"; exit 0; fi
echo "test-manage-autostart: $fails FAILURE(S)"
exit 1