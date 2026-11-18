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
case "$OUT" in *"TOPBAR_SHOW_NETSPEED = true"*) ok "status shows netspeed true" ;; *) no "status missing netspeed: $OUT" ;; esac
case "$OUT" in *"TOPBAR_NETSPEED_MODE = dual"*) ok "status shows netspeed mode default" ;; *) no "status missing netspeed mode: $OUT" ;; esac
case "$OUT" in *"TOPBAR_NETSPEED_LABELS = false"*) ok "status shows netspeed labels default" ;; *) no "status missing netspeed labels: $OUT" ;; esac

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

OUT="$(run toggle netspeed)"
case "$OUT" in *"Disabled:"*) ok "toggle netspeed off" ;; *) no "toggle netspeed failed: $OUT" ;; esac
if grep -q '^TOPBAR_SHOW_NETSPEED=false$' "$WORK/scripts/topbar-config"; then
    ok "netspeed config updated to false"
else
    no "netspeed config not updated"
fi
OUT="$(run toggle netspeed)"
case "$OUT" in *"Enabled:"*) ok "toggle netspeed on" ;; *) no "toggle netspeed on failed: $OUT" ;; esac

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
grep -q '^TOPBAR_NETSPEED_MODE=dual$' "$WORK/scripts/topbar-config" && ok "reset restores netspeed mode" || no "reset missing netspeed mode"
grep -q '^TOPBAR_NETSPEED_LABELS=false$' "$WORK/scripts/topbar-config" && ok "reset restores netspeed labels" || no "reset missing netspeed labels"

echo "=== test-manage-topbar: set netspeed mode ==="
OUT="$(run set TOPBAR_NETSPEED_MODE download)"
case "$OUT" in *"Set TOPBAR_NETSPEED_MODE=download"*) ok "set netspeed mode" ;; *) no "set netspeed mode failed: $OUT" ;; esac
grep -q '^TOPBAR_NETSPEED_MODE=download$' "$WORK/scripts/topbar-config" && ok "config reflects netspeed mode" || no "netspeed mode not updated"

echo "=== test-manage-topbar: netspeed-mode and netspeed-labels commands ==="
OUT="$(run netspeed-mode upload)"
case "$OUT" in *"TOPBAR_NETSPEED_MODE=upload"*) ok "netspeed-mode command sets mode" ;; *) no "netspeed-mode failed: $OUT" ;; esac
grep -q '^TOPBAR_NETSPEED_MODE=upload$' "$WORK/scripts/topbar-config" && ok "netspeed-mode updates config" || no "netspeed-mode config missing"
OUT="$(run netspeed-labels on)"
case "$OUT" in *"TOPBAR_NETSPEED_LABELS=true"*) ok "netspeed-labels on sets true" ;; *) no "netspeed-labels on failed: $OUT" ;; esac
grep -q '^TOPBAR_NETSPEED_LABELS=true$' "$WORK/scripts/topbar-config" && ok "netspeed-labels on updates config" || no "netspeed-labels on config missing"
OUT="$(run netspeed-labels off)"
case "$OUT" in *"TOPBAR_NETSPEED_LABELS=false"*) ok "netspeed-labels off sets false" ;; *) no "netspeed-labels off failed: $OUT" ;; esac
OUT="$(run netspeed-mode invalid 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "netspeed-mode rejects invalid value" || no "netspeed-mode should reject invalid value"

echo "=== test-manage-topbar: list ==="
OUT="$(run list)"
case "$OUT" in *"TOPBAR_SHOW_TRAY"*"true"*) ok "list shows tray true" ;; *) no "list missing: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-topbar: ALL PASS"; exit 0; fi
echo "test-manage-topbar: $fails FAILURE(S)"
exit 1