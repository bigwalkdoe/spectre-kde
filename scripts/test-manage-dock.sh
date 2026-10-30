#!/usr/bin/env bash
# Tests for scripts/manage-dock.sh.
#
# Uses a temporary WORK directory with fake desktop dirs and a fake
# dock-launchers.list so no real config is mutated.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# --- Build a fake repo tree in WORK ---
mkdir -p "$WORK/scripts"
mkdir -p "$WORK/usr/share/applications"
mkdir -p "$WORK/.local/share/applications"
mkdir -p "$WORK/usr/local/share/applications"
mkdir -p "$WORK/var/lib/flatpak/exports/share/applications"

# Fake .desktop files for find_app tests
cat > "$WORK/usr/share/applications/org.mozilla.firefox.desktop" <<'EOF'
[Desktop Entry]
Name=Firefox
EOF
cat > "$WORK/.local/share/applications/com.spotify.Client.desktop" <<'EOF'
[Desktop Entry]
Name=Spotify
EOF
# manage-dock.sh searches $HOME/.local/share/applications, so this app is
# visible to it even on a runner with no KDE apps installed. The find/add
# tests use it instead of borrowing a host app such as Firefox.
cat > "$WORK/.local/share/applications/org.spectre.FindMe.desktop" <<'EOF'
[Desktop Entry]
Name=Spectre Find Me
EOF

# Fake dock-config (ROOT becomes $WORK when script is in $WORK/scripts/)
cat > "$WORK/dock-config" <<'EOF'
DOCK_POSITION=bottom
DOCK_HEIGHT_MULTIPLIER=26/9
DOCK_FLOATING=true
DOCK_CENTERED=true
EOF

# Initial dock-launchers.list
cat > "$WORK/scripts/dock-launchers.list" <<'EOF'
# spectre-kde -- pinned dock launchers
org.kde.dolphin.desktop                  # Files
org.mozilla.firefox.desktop              # Web
EOF

# --- Copy manage-dock.sh into WORK and patch its paths ---
cp "$ROOT/scripts/manage-dock.sh" "$WORK/scripts/manage-dock.sh"
chmod +x "$WORK/scripts/manage-dock.sh"

run_dock(){
  HOME="$WORK" bash "$WORK/scripts/manage-dock.sh" "$@"
}

echo "=== test-manage-dock: list ==="
OUT="$(run_dock list)"
case "$OUT" in
  *"org.kde.dolphin.desktop"*) ok "list shows dolphin" ;;
  *) no "list missing dolphin: $OUT" ;;
esac
case "$OUT" in
  *"org.mozilla.firefox.desktop"*) ok "list shows firefox" ;;
  *) no "list missing firefox: $OUT" ;;
esac

echo "=== test-manage-dock: config ==="
OUT="$(run_dock config)"
case "$OUT" in
  *"DOCK_POSITION=bottom"*) ok "config shows DOCK_POSITION" ;;
  *) no "config missing DOCK_POSITION: $OUT" ;;
esac

echo "=== test-manage-dock: find ==="
OUT="$(run_dock find spectre)"
case "$OUT" in
  *"org.spectre.FindMe.desktop"*) ok "find spectre returns the fake app" ;;
  *) no "find spectre missing: $OUT" ;;
esac
case "$OUT" in
  *"$WORK/.local/share/applications/org.spectre.FindMe.desktop"*)
    ok "find reports the isolated app path" ;;
  *) no "find did not read the isolated app dir: $OUT" ;;
esac
OUT="$(run_dock find spectre-nonexistent-app-xyz)"
case "$OUT" in
  *"No applications found"* ) ok "find nonexistent reports not found" ;;
  *) no "find nonexistent should report not found: $OUT" ;;
esac

echo "=== test-manage-dock: add new ==="
run_dock add org.spectre.FindMe.desktop
OUT="$(grep '^org.spectre.FindMe.desktop' "$WORK/scripts/dock-launchers.list")"
case "$OUT" in
  *"org.spectre.FindMe.desktop"*) ok "add appends FindMe to list" ;;
  *) no "add did not append FindMe" ;;
esac
case "$OUT" in
  *"# Spectre Find Me"*) ok "add includes app name comment" ;;
  *) no "add missing name comment" ;;
esac

echo "=== test-manage-dock: add duplicate ==="
OUT="$(run_dock add org.kde.dolphin.desktop 2>&1)"
case "$OUT" in
  *"already in the dock list"*) ok "add duplicate warns" ;;
  *) no "add duplicate should warn: $OUT" ;;
esac

echo "=== test-manage-dock: add by path ==="
run_dock add "$WORK/usr/share/applications/org.mozilla.firefox.desktop"
COUNT="$(grep -c '^org.mozilla.firefox.desktop' "$WORK/scripts/dock-launchers.list")"
[ "$COUNT" -eq 1 ] && ok "add by path doesn't duplicate" || no "add by path duplicated firefox (count=$COUNT)"

echo "=== test-manage-dock: remove ==="
run_dock remove org.kde.dolphin.desktop
if grep -q '^org.kde.dolphin.desktop' "$WORK/scripts/dock-launchers.list"; then
  no "remove did not remove dolphin"
else
  ok "remove removes dolphin from list"
fi
[ -f "$WORK/scripts/dock-launchers.list.bak" ] && ok "remove creates backup" || no "remove missing backup"

echo "=== test-manage-dock: remove missing ==="
OUT="$(run_dock remove org.kde.nonexistent.desktop 2>&1)"
rc=$?
case "$OUT" in
  *"not found in dock list"*) ok "remove missing reports error" ;;
  *) no "remove missing should report error: $OUT" ;;
esac
[ "$rc" -ne 0 ] && ok "remove missing exits non-zero" || no "remove missing should exit non-zero"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-manage-dock: ALL PASS"
  exit 0
fi
echo "test-manage-dock: $fails FAILURE(S)"
exit 1
