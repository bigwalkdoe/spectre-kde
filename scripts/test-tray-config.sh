#!/usr/bin/env bash
# Tests for scripts/tray-config.js invariants.
#
# The clipboard applet was dropped from the pinned tray items once (commit
# 6776482) and had to be restored; this suite guards against that regression.
# Also asserts the tray curation stays reload-free, because forcing a reload
# nulls tray items and makes the whole tray "unavailable" in Plasma 6.7.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

TC="$ROOT/scripts/tray-config.js"
APP="$ROOT/config/applied-appletsrc.conf"

echo "=== test-tray-config: file present ==="
if [ -f "$TC" ]; then ok "tray-config.js exists"; else no "tray-config.js missing"; fi

echo "=== test-tray-config: clipboard pinned ==="
if grep -q 'org.kde.plasma.clipboard' "$TC"; then
    ok "clipboard present in tray-config.js"
else
    no "clipboard missing from tray-config.js"
fi

# clipboard must be inside the ITEMS list that feeds extraItems/shownItems
if python3 - "$TC" <<'PY' >/dev/null 2>&1
import re,sys
s=open(sys.argv[1]).read()
m=re.search(r'var ITEMS\s*=\s*(.*?);', s, re.S)
sys.exit(0 if m and 'org.kde.plasma.clipboard' in m.group(1) else 1)
PY
then
    ok "clipboard is in the ITEMS list"
else
    no "clipboard not found in ITEMS list"
fi

echo "=== test-tray-config: matches applied snapshot ==="
SNAP="$(sed -n 's/^extraItems=//p' "$APP" | head -1)"
LIVE="$(python3 - "$TC" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
m=re.search(r'var ITEMS\s*=\s*(.*?);', s, re.S)
if not m:
    print(""); sys.exit()
print(','.join(re.findall(r'"(org\.kde\.plasma\.[A-Za-z0-9.-]+),?"', m.group(1))))
PY
)"
if [ "$SNAP" = "$LIVE" ]; then
    ok "tray extraItems matches applied-appletsrc.conf ($SNAP)"
else
    no "tray extraItems drift" "snapshot=$SNAP live=$LIVE"
fi

echo "=== test-tray-config: no forced reload ==="
if grep -q 'reloadConfig' "$TC"; then
    no "reloadConfig() must not be called (nulls tray items)"
else
    ok "no reloadConfig() call"
fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
    echo "test-tray-config: ALL PASS"
    exit 0
fi
echo "test-tray-config: $fails FAILURE(S)"
exit 1