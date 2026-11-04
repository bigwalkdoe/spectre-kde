#!/usr/bin/env bash
# Tests for scripts/render-kwinrules.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/bin" "$WORK/config"
cp "$ROOT/config/applied-kwinrulesrc.conf" "$WORK/config/applied-kwinrulesrc.conf"

# Stub kreadconfig6 so the suite runs without a live session; returns a UUID
# per Id_N key regardless of file.
cat > "$WORK/bin/kreadconfig6" << 'STUB'
#!/bin/sh
key=""
prev=""
for a in "$@"; do
    [ "$prev" = "--key" ] && key="$a"
    prev="$a"
done
case "$key" in
    Id_1) echo "uuid-1-test" ;;
    Id_2) echo "uuid-2-test" ;;
    Id_3) echo "uuid-3-test" ;;
    Id_4) echo "uuid-4-test" ;;
    *) exit 1 ;;
esac
STUB
chmod +x "$WORK/bin/kreadconfig6"
export PATH="$WORK/bin:$PATH"

# Copy the script where it can find the config via its own ROOT
mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/render-kwinrules.sh" "$WORK/scripts/render-kwinrules.sh"
chmod +x "$WORK/scripts/render-kwinrules.sh"

run(){ bash "$WORK/scripts/render-kwinrules.sh"; }

echo "=== test-render-kwinrules: resolves placeholders ==="
OUT="$(run)"
case "$OUT" in *"desktops=uuid-2-test"*) ok "DESKTOP_2 resolved" ;; *) no "DESKTOP_2 not resolved: $OUT" ;; esac
case "$OUT" in *"desktops=uuid-3-test"*) ok "DESKTOP_3 resolved" ;; *) no "DESKTOP_3 not resolved: $OUT" ;; esac
case "$OUT" in *"desktops=@DESKTOP_"*) no "unresolved placeholder remains" ;; *) ok "no placeholders remain" ;; esac
case "$OUT" in *"Order=1,2,3,4,5,6,7"*) ok "Order list preserved" ;; *) no "Order list missing" ;; esac

echo "=== test-render-kwinrules: fails cleanly when ids are missing ==="
cat > "$WORK/bin/kreadconfig6" << 'STUB'
#!/bin/sh
exit 1
STUB
chmod +x "$WORK/bin/kreadconfig6"
OUT="$(run 2>&1)" || true
case "$OUT" in *"unresolved desktop placeholder"*) ok "reports unresolved placeholder" ;; *) no "did not report unresolved placeholder: $OUT" ;; esac
case "$OUT" in *"[General]"*) no "printed partial file on failure" ;; *) ok "prints no partial file on failure" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-render-kwinrules: ALL PASS"; exit 0; fi
echo "test-render-kwinrules: $fails FAILURE(S)"
exit 1
