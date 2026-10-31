#!/usr/bin/env bash
# Tests for the lock screen integrity check in verify.sh.
#
# verify.sh reads the system MainBlock.qml path from SPECTRE_LOCK_MAIN (falling
# back to the real system path), so this suite can exercise both the empty and
# non-empty branches without touching /usr/share.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "$2"; fails=$((fails + 1)); }

NONEMPTY="$WORK/MainBlock.nonempty.qml"
EMPTY="$WORK/MainBlock.empty.qml"
printf '%s\n' 'import QtQuick' > "$NONEMPTY"
: > "$EMPTY"

# Non-empty file -> PASS
OUT="$(SPECTRE_LOCK_MAIN="$NONEMPTY" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
case "$OUT" in
  *"PASS  lock screen MainBlock.qml non-empty"*) ok "non-empty MainBlock reports PASS" ;;
  *) no "non-empty MainBlock reports PASS" "got: $(printf '%s' "$OUT" | grep -i 'MainBlock' | head -1)" ;;
esac

# Empty file -> FAIL (not SKIP/PASS)
OUT="$(SPECTRE_LOCK_MAIN="$EMPTY" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
case "$OUT" in
  *"FAIL  lock screen MainBlock.qml non-empty"*) ok "empty MainBlock reports FAIL" ;;
  *) no "empty MainBlock reports FAIL" "got: $(printf '%s' "$OUT" | grep -i 'MainBlock' | head -1)" ;;
esac

# Missing file -> SKIP
MISSING="$WORK/does-not-exist.qml"
OUT="$(SPECTRE_LOCK_MAIN="$MISSING" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
case "$OUT" in
  *"SKIP  lock screen shell not installed"*) ok "missing MainBlock reports SKIP" ;;
  *) no "missing MainBlock reports SKIP" "got: $(printf '%s' "$OUT" | grep -i 'lock screen' | head -1)" ;;
esac

if [ "$fails" -eq 0 ]; then printf '%s\n' "PASS lockscreen integrity"; else printf '%s\n' "FAIL lockscreen integrity"; exit 1; fi