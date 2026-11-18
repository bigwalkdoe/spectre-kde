#!/usr/bin/env bash
# Tests for scripts/manage-tray.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# Build a fake repo tree
mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/manage-tray.sh" "$WORK/scripts/manage-tray.sh"
chmod +x "$WORK/scripts/manage-tray.sh"
# seed tray-config.js from root (real one)
cp "$ROOT/scripts/tray-config.js" "$WORK/scripts/tray-config.js"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-tray.sh" "$@"; }

echo "=== test-manage-tray: list ==="
OUT="$(run list)"
case "$OUT" in *"org.kde.plasma.clipboard"*) ok "list shows clipboard" ;; *) no "list missing clipboard: $OUT" ;; esac

echo "=== test-manage-tray: status ==="
OUT="$(run status)"
case "$OUT" in *"exists"*) ok "status shows exists" ;; *) no "status missing exists: $OUT" ;; esac

echo "=== test-manage-tray: unpin + pin ==="
OUT="$(run unpin battery)"
case "$OUT" in *"Unpinned:"*) ok "unpin battery" ;; *) no "unpin failed: $OUT" ;; esac
if grep -q 'org.kde.plasma.battery' "$WORK/scripts/tray-config.js"; then
    no "battery still present after unpin"
else
    ok "battery removed after unpin"
fi
OUT="$(run pin battery)"
case "$OUT" in *"Pinned:"*) ok "pin battery" ;; *) no "pin failed: $OUT" ;; esac
if grep -q 'org.kde.plasma.battery' "$WORK/scripts/tray-config.js"; then
    ok "battery present after pin"
else
    no "battery missing after pin"
fi

echo "=== test-manage-tray: reset ==="
# remove clipboard to test reset restores it
sed -i '/org.kde.plasma.clipboard/d' "$WORK/scripts/tray-config.js"
if grep -q 'org.kde.plasma.clipboard' "$WORK/scripts/tray-config.js"; then
    no "clipboard still present after sed removal"
else
    ok "clipboard removed for reset test"
fi
OUT="$(run reset)"
case "$OUT" in *"Reset"*) ok "reset ran" ;; *) no "reset failed: $OUT" ;; esac
if grep -q 'org.kde.plasma.clipboard' "$WORK/scripts/tray-config.js"; then
    ok "clipboard restored by reset"
else
    no "clipboard not restored by reset"
fi

echo "=== test-manage-tray: pin short name ==="
OUT="$(run pin volume)"
case "$OUT" in *"Already pinned:"*) ok "short name volume recognized as already pinned" ;; *) no "short name not recognized: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-tray: ALL PASS"; exit 0; fi
echo "test-manage-tray: $fails FAILURE(S)"
exit 1