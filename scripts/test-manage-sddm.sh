#!/usr/bin/env bash
# Tests for scripts/manage-sddm.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/etc/sddm.conf.d" "$WORK/usr/share/sddm/themes/Orchis-Mac"
cp "$ROOT/scripts/manage-sddm.sh" "$WORK/scripts/manage-sddm.sh"
chmod +x "$WORK/scripts/manage-sddm.sh"

# Create a fake config
cat > "$WORK/etc/sddm.conf.d/theme.conf" << 'CONF'
[Theme]
Current=Orchis-Mac
CursorTheme=Bibata-Modern-Ice
Font=Inter,10,-1,5,50,0,0,0,0,0
CONF

# Override paths in the script by sourcing in modified environment
run(){ 
    SDDM_CONF="$WORK/etc/sddm.conf.d/theme.conf" \
    SDDM_THEME_DIR="$WORK/usr/share/sddm/themes" \
    SDDM_THEME_NAME="Orchis-Mac" \
    bash "$WORK/scripts/manage-sddm.sh" "$@"
}

echo "=== test-manage-sddm: status ==="
OUT="$(run status 2>&1)"
case "$OUT" in *"Orchis-Mac"*) ok "status shows theme" ;; *) no "status failed: $OUT" ;; esac

echo "=== test-manage-sddm: current ==="
OUT="$(run current 2>&1)"
case "$OUT" in *"SDDM Status:"*) ok "current works" ;; *) no "current failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-sddm: ALL PASS"; exit 0; fi
echo "test-manage-sddm: $fails FAILURE(S)"
exit 1
