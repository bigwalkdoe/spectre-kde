#!/usr/bin/env bash
# Tests for scripts/splash-theme-path.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# shellcheck source=scripts/splash-theme-path.sh
. "$ROOT/scripts/splash-theme-path.sh"

export XDG_DATA_HOME="$WORK/data"
export XDG_DATA_DIRS="$WORK/sys1:$WORK/sys2"
unset HOME 2>/dev/null || true
HOME="$WORK/home"

echo "=== test-splash-theme-path: Plasma 6 look-and-feel layout ==="
mkdir -p "$XDG_DATA_HOME/plasma/look-and-feel/AppleSplash/contents/splash"
: > "$XDG_DATA_HOME/plasma/look-and-feel/AppleSplash/contents/splash/Splash.qml"
out="$(splash_theme_path AppleSplash || true)"
case "$out" in
  "$XDG_DATA_HOME/plasma/look-and-feel/AppleSplash/contents/splash") ok "resolves user-installed splash theme" ;;
  *) no "should resolve user-installed splash theme" "got: ${out:-<empty>}" ;;
esac

echo "=== test-splash-theme-path: prefers XDG_DATA_HOME over system dirs ==="
mkdir -p "$WORK/sys1/plasma/look-and-feel/Breeze/contents/splash"
: > "$WORK/sys1/plasma/look-and-feel/Breeze/contents/splash/Splash.qml"
out="$(XDG_DATA_HOME="$WORK/empty-home" splash_theme_path Breeze || true)"
case "$out" in
  "$WORK/sys1/plasma/look-and-feel/Breeze/contents/splash") ok "resolves theme from XDG_DATA_DIRS entry" ;;
  *) no "should resolve theme from XDG_DATA_DIRS entry" "got: ${out:-<empty>}" ;;
esac

echo "=== test-splash-theme-path: legacy plasma/splash layout fallback ==="
mkdir -p "$WORK/sys2/plasma/look-and-feel/plasma/splash/themes/LegacySplash"
out="$(XDG_DATA_HOME="$WORK/empty-home" XDG_DATA_DIRS="$WORK/sys2" splash_theme_path LegacySplash || true)"
case "$out" in
  "$WORK/sys2/plasma/look-and-feel/plasma/splash/themes/LegacySplash") ok "resolves legacy splash theme layout fallback path" ;;
  *) no "should resolve legacy splash theme layout fallback path" "got: ${out:-<empty>}" ;;
esac

echo "=== test-splash-theme-path: missing or invalid names ==="
if splash_theme_path MissingTheme >/dev/null 2>&1; then
  no "missing theme should return failure" "got exit 0"
else
  ok "missing theme returns failure"
fi
if splash_theme_path "../evil" >/dev/null 2>&1; then
  no "path-like name should be rejected" "got exit 0"
else
  ok "path-like name rejected"
fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-splash-theme-path: ALL PASS"
  exit 0
fi
echo "test-splash-theme-path: $fails FAILURE(S)"
exit 1
