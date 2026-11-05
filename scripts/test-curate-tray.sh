#!/usr/bin/env bash
# Tests for scripts/curate-tray.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/bin"
cp "$ROOT/scripts/curate-tray.sh" "$WORK/scripts/curate-tray.sh"
cp "$ROOT/scripts/tray-config.js" "$WORK/scripts/tray-config.js"
chmod +x "$WORK/scripts/curate-tray.sh"

# Stub busctl: pretends plasmashell owns its bus name.
cat > "$WORK/bin/busctl" << 'STUB'
#!/bin/sh
echo "org.kde.plasmashell  12345 plasmashell deon :1.1 user@1001.service - -"
exit 0
STUB
# Stub gdbus: answers evaluateScript based on the JS payload it receives.
cat > "$WORK/bin/gdbus" << 'STUB'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        *'writeConfig("extraItems", "")'*) echo "('\"tray cleared\"',)"; exit 0 ;;
        *'systemtray curated'*) echo "('\"systemtray curated\"',)"; exit 0 ;;
    esac
done
echo "('\"unexpected\"',)"
exit 0
STUB
chmod +x "$WORK/bin/busctl" "$WORK/bin/gdbus"
export PATH="$WORK/bin:$PATH"

# Keep the plasmashell-absent case fast: one retry, no second of sleep.
run(){ CURATE_TRAY_RETRIES=1 bash "$WORK/scripts/curate-tray.sh"; }

echo "=== test-curate-tray: happy path ==="
OUT="$(run 2>&1)"
case "$OUT" in *"system tray curated"*) ok "reports curated" ;; *) no "did not report curated: $OUT" ;; esac

echo "=== test-curate-tray: rejects failure responses ==="
cat > "$WORK/bin/gdbus" << 'STUB'
#!/bin/sh
echo "('\"ERROR systemtray not found in any panel\"',)"
exit 0
STUB
chmod +x "$WORK/bin/gdbus"
OUT="$(run 2>&1)" && RC=0 || RC=$?
if [ "${RC:-0}" -ne 0 ]; then ok "exits non-zero on clear failure"; else no "did not fail on clear failure: $OUT"; fi
case "$OUT" in *"clear phase failed"*) ok "reports clear failure" ;; *) no "missing clear failure message: $OUT" ;; esac

echo "=== test-curate-tray: fails when plasmashell is absent ==="
cat > "$WORK/bin/busctl" << 'STUB'
#!/bin/sh
exit 0
STUB
chmod +x "$WORK/bin/busctl"
OUT="$(run 2>&1)" && RC=0 || RC=$?
if [ "${RC:-0}" -ne 0 ]; then ok "exits non-zero without plasmashell"; else no "did not fail without plasmashell" ; fi
case "$OUT" in *"plasmashell is not running"*) ok "reports missing plasmashell" ;; *) no "missing plasmashell message: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-curate-tray: ALL PASS"; exit 0; fi
echo "test-curate-tray: $fails FAILURE(S)"
exit 1
