#!/usr/bin/env bash
# Tests for config/applied-appletsrc.conf invariants.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

F="$ROOT/config/applied-appletsrc.conf"

echo "=== test-appletsrc: file present ==="
if [ -f "$F" ]; then ok "applied-appletsrc.conf exists"; else no "missing"; fi

echo "=== test-appletsrc: wallpaper version ==="
if grep -q 'wavy_lines_v01_5120x2880.png' "$F"; then
    no "stale v01 wallpaper reference found"
else
    ok "no stale v01 wallpaper reference"
fi
if grep -q 'wavy_lines_v02_5120x2880.png' "$F"; then
    ok "uses v02 wallpaper asset"
else
    no "v02 wallpaper asset not referenced"
fi

echo "=== test-appletsrc: clipboard pinned ==="
if grep -q '^extraItems=.*org.kde.plasma.clipboard' "$F"; then
    ok "clipboard in extraItems"
else
    no "clipboard missing from extraItems"
fi
if grep -q '^plugin=org.kde.plasma.clipboard$' "$F"; then
    ok "clipboard applet present"
else
    no "clipboard applet missing"
fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-appletsrc: ALL PASS"; exit 0; fi
echo "test-appletsrc: $fails FAILURE(S)"
exit 1