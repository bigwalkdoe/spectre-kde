#!/usr/bin/env bash
# Tests for scripts/preflight-check.sh (targeted, stubbed environment).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# Build minimal fake repo layout expected by preflight-check.sh
mkdir -p "$WORK/repo/scripts" "$WORK/repo/config" "$WORK/repo/assets/wallpapers"
cp "$ROOT/scripts/preflight-check.sh" "$WORK/repo/scripts/preflight-check.sh"
chmod +x "$WORK/repo/scripts/preflight-check.sh"

# required repo files checked by script
for f in apply.sh verify.sh scripts/layout.js scripts/dock-launchers.list scripts/tray-config.js scripts/manage-tray.sh scripts/resolve-launchers.sh scripts/restore-backup.sh; do
  mkdir -p "$WORK/repo/$(dirname "$f")"
  : > "$WORK/repo/$f"
done
chmod +x "$WORK/repo/apply.sh"
: > "$WORK/repo/assets/wallpapers/wavy_lines_v02_5120x2880.png"

cat > "$WORK/repo/scripts/dock-config" <<'EOF'
DOCK_POSITION=bottom
DOCK_HEIGHT_MULTIPLIER=26/9
DOCK_FLOATING=true
DOCK_CENTERED=true
EOF
cat > "$WORK/repo/scripts/topbar-config" <<'EOF'
TOPBAR_HEIGHT_MULTIPLIER=10/6
TOPBAR_SHOW_APP_MENU=true
TOPBAR_SHOW_PAGER=true
TOPBAR_SHOW_NETSPEED=true
TOPBAR_SHOW_TRAY=true
TOPBAR_SHOW_CLOCK=true
EOF
: > "$WORK/repo/config/applied-kwinrulesrc.conf"
: > "$WORK/repo/config/applied-sddm.conf"

# stub tools
mkdir -p "$WORK/bin" "$WORK/home/.config" "$WORK/home/.local/share/plasma/look-and-feel/com.github.vinceliuice.Orchis" \
         "$WORK/home/.local/share/color-schemes" "$WORK/home/.local/share/icons/FairyWren_Light" "$WORK/home/.local/share/icons/Bibata-Modern-Ice"
: > "$WORK/home/.local/share/color-schemes/Orchis.colors"

for tool in plasmashell kwriteconfig6 plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-lookandfeel plasma-apply-wallpaperimage gdbus busctl uuidgen flock fc-cache; do
  if [ "$tool" = "plasmashell" ]; then
    cat > "$WORK/bin/plasmashell" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "--version" ]; then echo "plasmashell 6.3.4"; fi
exit 0
STUB
  else
    cat > "$WORK/bin/$tool" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  fi
  chmod +x "$WORK/bin/$tool"
done
cat > "$WORK/bin/df" <<'STUB'
#!/usr/bin/env bash
echo "Filesystem 1K-blocks Used Available Use% Mounted on"
echo "/dev/fake 1000000 100000 900000 10% /home"
STUB
chmod +x "$WORK/bin/df"

run_pf(){
  PATH="$WORK/bin:$PATH" HOME="$WORK/home" XDG_CURRENT_DESKTOP=KDE WAYLAND_DISPLAY=wayland-1 \
    bash "$WORK/repo/scripts/preflight-check.sh" "$@"
}

echo "=== test-preflight-check: passes in healthy stubbed environment ==="
OUT="$(run_pf --light 2>&1)"; RC=$?
case "$OUT" in *"Preflight PASSED"*) ok "reports pass summary" ;; *) no "missing pass summary: $OUT" ;; esac
[ "$RC" -eq 0 ] && ok "exits 0 when healthy" || no "healthy exit $RC"

echo "=== test-preflight-check: fails when required tool missing ==="
mkdir -p "$WORK/bin-missing" "$WORK/core"
for t in "$WORK/bin"/*; do
  b="$(basename "$t")"
  [ "$b" = "plasmashell" ] && continue
  ln -s "$t" "$WORK/bin-missing/$b"
done
for c in bash sh env cat grep sed awk tr cut sort uniq head tail wc mkdir cp mv rm chmod ls df find printf test readlink dirname basename mktemp uname seq tee; do
  p="$(command -v "$c" 2>/dev/null || true)"
  [ -n "$p" ] && ln -s "$p" "$WORK/core/$c" 2>/dev/null || true
done
OUT="$(PATH="$WORK/bin-missing:$WORK/core" HOME="$WORK/home" XDG_CURRENT_DESKTOP=KDE WAYLAND_DISPLAY=wayland-1 \
  bash "$WORK/repo/scripts/preflight-check.sh" --light 2>&1)"; RC=$?
case "$OUT" in *"plasmashell not found"*) ok "reports missing plasmashell" ;; *) no "missing tool not reported: $OUT" ;; esac
case "$OUT" in *"Preflight FAILED"*) ok "reports failed summary" ;; *) no "missing failed summary: $OUT" ;; esac
[ "$RC" -ne 0 ] && ok "exits non-zero on error" || no "expected failure exit"

echo "=== test-preflight-check: warns when optional/config items missing ==="
rm -f "$WORK/repo/scripts/topbar-config"
OUT="$(run_pf --light 2>&1)"; RC=$?
case "$OUT" in *"topbar-config missing"*) ok "warns on missing topbar-config" ;; *) no "missing warning: $OUT" ;; esac
case "$OUT" in *"Preflight passed with warnings"*|*"Preflight PASSED"*) ok "does not hard-fail on warning-only case" ;; *) no "unexpected summary: $OUT" ;; esac
[ "$RC" -eq 0 ] && ok "warning-only exits 0" || no "warning-only exit $RC"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-preflight-check: ALL PASS"; exit 0; fi
echo "test-preflight-check: $fails FAILURE(S)"
exit 1
