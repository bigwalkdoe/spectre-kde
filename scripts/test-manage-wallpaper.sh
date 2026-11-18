#!/usr/bin/env bash
# Tests for scripts/manage-wallpaper.sh (list only; set requires a live session).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/assets/wallpapers"
cp "$ROOT/scripts/manage-wallpaper.sh" "$WORK/scripts/manage-wallpaper.sh"
chmod +x "$WORK/scripts/manage-wallpaper.sh"
# vendored asset
cp "$ROOT/assets/wallpapers/wavy_lines_v02_5120x2880.png" "$WORK/assets/wallpapers/" 2>/dev/null || true
mkdir -p "$WORK/.local/share/wallpapers/kde-setup-02"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-wallpaper.sh" "$@"; }

echo "=== test-manage-wallpaper: list ==="
OUT="$(run list)"
case "$OUT" in *"wavy_lines_v02_5120x2880.png"*) ok "list shows vendored wallpaper" ;; *) no "list missing wallpaper: $OUT" ;; esac

echo "=== test-manage-wallpaper: set vendored ==="
OUT="$(run set wavy_lines_v02_5120x2880.png 2>&1)" || true
case "$OUT" in *"Wallpaper updated"*|*"Could not update"*|*"Warning:"*) ok "set handled gracefully without live session" ;; *) no "set unexpected: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-wallpaper: ALL PASS"; exit 0; fi
echo "test-manage-wallpaper: $fails FAILURE(S)"
exit 1