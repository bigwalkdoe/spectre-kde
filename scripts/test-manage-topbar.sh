#!/usr/bin/env bash
# Tests for scripts/manage-topbar.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/manage-topbar.sh" "$WORK/scripts/manage-topbar.sh"
cp "$ROOT/scripts/topbar-config" "$WORK/scripts/topbar-config"
chmod +x "$WORK/scripts/manage-topbar.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-topbar.sh" "$@"; }

echo "=== test-manage-topbar: status defaults ==="
OUT="$(run status)"
case "$OUT" in *"TOPBAR_SHOW_CLOCK = true"*) ok "status shows clock true" ;; *) no "status missing: $OUT" ;; esac

echo "=== test-manage-topbar: toggle ==="
OUT="$(run toggle clock)"
case "$OUT" in *"Disabled:"*) ok "toggle clock off" ;; *) no "toggle failed: $OUT" ;; esac
# verify config file updated
if grep -q '^TOPBAR_SHOW_CLOCK=false$' "$WORK/scripts/topbar-config"; then
    ok "config updated to false"
else
    no "config not updated"
fi
OUT="$(run toggle clock)"
case "$OUT" in *"Enabled:"*) ok "toggle clock on" ;; *) no "toggle on failed: $OUT" ;; esac

echo "=== test-manage-topbar: set ==="
OUT="$(run set TOPBAR_HEIGHT_MULTIPLIER 12/6)"
case "$OUT" in *"Set TOPBAR_HEIGHT_MULTIPLIER=12/6"*) ok "set worked" ;; *) no "set failed: $OUT" ;; esac
if grep -q '^TOPBAR_HEIGHT_MULTIPLIER=12/6$' "$WORK/scripts/topbar-config"; then
    ok "config reflects set"
else
    no "config not updated by set"
fi

echo "=== test-manage-topbar: reset ==="
OUT="$(run reset)"
case "$OUT" in *"Reset top bar to defaults"*) ok "reset ran" ;; *) no "reset failed: $OUT" ;; esac
if grep -q '^TOPBAR_SHOW_CLOCK=true$' "$WORK/scripts/topbar-config"; then
    ok "reset restored clock=true"
else
    no "reset did not restore defaults"
fi

echo "=== test-manage-topbar: list ==="
OUT="$(run list)"
case "$OUT" in *"TOPBAR_SHOW_TRAY"*"true"*) ok "list shows tray true" ;; *) no "list missing: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-topbar: ALL PASS"; exit 0; fi
echo "test-manage-topbar: $fails FAILURE(S)"
exit 1