#!/usr/bin/env bash
# Tests for scripts/manage-kwin-rules.sh (list/show only).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/config"
cp "$ROOT/scripts/manage-kwin-rules.sh" "$WORK/scripts/manage-kwin-rules.sh"
cp "$ROOT/config/applied-kwinrulesrc.conf" "$WORK/config/applied-kwinrulesrc.conf"
chmod +x "$WORK/scripts/manage-kwin-rules.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-kwin-rules.sh" "$@"; }

echo "=== test-manage-kwin-rules: list ==="
OUT="$(run list)"
case "$OUT" in *"Konsole - borderless"*) ok "list shows Konsole rule" ;; *) no "list missing Konsole: $OUT" ;; esac
case "$OUT" in *"Firefox - desktop 2"*) ok "list shows Firefox rule" ;; *) no "list missing Firefox: $OUT" ;; esac
case "$OUT" in *"Spotify - keep above"*) ok "list shows Spotify rule" ;; *) no "list missing Spotify: $OUT" ;; esac

echo "=== test-manage-kwin-rules: show ==="
OUT="$(run show 'Konsole - borderless')"
case "$OUT" in *"Konsole - borderless"*) ok "show works" ;; *) no "show failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-kwin-rules: ALL PASS"; exit 0; fi
echo "test-manage-kwin-rules: $fails FAILURE(S)"
exit 1