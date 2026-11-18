#!/usr/bin/env bash
# Tests for scripts/restore-backup.sh (file restore behavior with stubbed system tools).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/bin" "$WORK/home/.config" "$WORK/home/.local/share/plasma/look-and-feel"
# Stub external commands used by restore-backup.sh
for cmd in systemctl busctl pkill fc-cache sleep setsid nohup plasmashell; do
  cat > "$WORK/bin/$cmd" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
  chmod +x "$WORK/bin/$cmd"
done
# busctl list: report no plasmashell by default so shutdown/start waits complete quickly under stubbed sleep.
cat > "$WORK/bin/busctl" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "--user" ] && [ "$2" = "list" ]; then
  exit 0
fi
exit 0
STUB
chmod +x "$WORK/bin/busctl"

echo "=== test-restore-backup: restores files, removes absent ones, handles extras ==="
BK="$WORK/home/.config/kde-backups/20261118-000000"
mkdir -p "$BK" "$BK/gtk-3.0" "$BK/gtk-4.0" "$BK/fontconfig" "$BK/lnf/com.github.vinceliuice.Orchis/contents"
# files present in backup
echo "backup-kdeglobals" > "$BK/kdeglobals"
echo "backup-kwinrc" > "$BK/kwinrc"
echo "gtk3-backup" > "$BK/gtk-3.0/settings.ini"
echo "gtk4-backup" > "$BK/gtk-4.0/settings.ini"
echo "font-backup" > "$BK/fontconfig/fonts.conf"
echo "cursorTheme=Bibata-Modern-Ice" > "$BK/lnf/com.github.vinceliuice.Orchis/contents/defaults"
echo "absent" > "$BK/wallpaper.state"
# one affected file intentionally absent in backup to trigger removal (e.g. plasmarc)

# current state differs
mkdir -p "$WORK/home/.config/gtk-3.0" "$WORK/home/.config/gtk-4.0" "$WORK/home/.config/fontconfig" \
         "$WORK/home/.local/share/plasma/look-and-feel/com.github.vinceliuice.Orchis/contents" \
         "$WORK/home/.local/share/wallpapers/kde-setup-02"
echo "current-kdeglobals" > "$WORK/home/.config/kdeglobals"
echo "current-kwinrc" > "$WORK/home/.config/kwinrc"
echo "current-plasmarc" > "$WORK/home/.config/plasmarc"
echo "gtk3-current" > "$WORK/home/.config/gtk-3.0/settings.ini"
echo "font-current" > "$WORK/home/.config/fontconfig/fonts.conf"
echo "current-defaults" > "$WORK/home/.local/share/plasma/look-and-feel/com.github.vinceliuice.Orchis/contents/defaults"
echo "wall" > "$WORK/home/.local/share/wallpapers/kde-setup-02/wavy_lines_v02_5120x2880.png"

OUT="$(PATH="$WORK/bin:$PATH" HOME="$WORK/home" BUSCTL_SHELL_PRESENT=1 bash "$ROOT/scripts/restore-backup.sh" "$BK" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "restore exits 0 for valid backup" || no "restore exit $RC: $OUT"
[ "$(cat "$WORK/home/.config/kdeglobals")" = "backup-kdeglobals" ] && ok "restores present affected file" || no "kdeglobals not restored"
[ "$(cat "$WORK/home/.config/kwinrc")" = "backup-kwinrc" ] && ok "restores another affected file" || no "kwinrc not restored"
[ ! -f "$WORK/home/.config/plasmarc" ] && ok "removes affected file absent from backup" || no "plasmarc should be removed"
[ "$(cat "$WORK/home/.config/gtk-3.0/settings.ini")" = "gtk3-backup" ] && ok "restores gtk settings" || no "gtk settings not restored"
[ "$(cat "$WORK/home/.config/fontconfig/fonts.conf")" = "font-backup" ] && ok "restores fontconfig" || no "fontconfig not restored"
[ "$(cat "$WORK/home/.local/share/plasma/look-and-feel/com.github.vinceliuice.Orchis/contents/defaults")" = "cursorTheme=Bibata-Modern-Ice" ] && ok "restores LNF defaults" || no "LNF defaults not restored"
[ ! -f "$WORK/home/.local/share/wallpapers/kde-setup-02/wavy_lines_v02_5120x2880.png" ] && ok "removes wallpaper when backup marked absent" || no "wallpaper should be removed"

echo "=== test-restore-backup: removes fontconfig when absent in backup ==="
BK2="$WORK/home/.config/kde-backups/20261118-000001"
mkdir -p "$BK2"
echo "current" > "$WORK/home/.config/fontconfig/fonts.conf"
OUT="$(PATH="$WORK/bin:$PATH" HOME="$WORK/home" BUSCTL_SHELL_PRESENT=1 bash "$ROOT/scripts/restore-backup.sh" "$BK2" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "restore exits 0 without fontconfig dir in backup" || no "restore2 exit $RC: $OUT"
[ ! -f "$WORK/home/.config/fontconfig/fonts.conf" ] && ok "removes fontconfig when absent in backup" || no "fontconfig should be removed when absent"

echo "=== test-restore-backup: fails for missing backup dir ==="
OUT="$(PATH="$WORK/bin:$PATH" HOME="$WORK/home" bash "$ROOT/scripts/restore-backup.sh" "$WORK/home/.config/kde-backups/nope" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "fails on missing backup dir" || no "should fail on missing backup rc=$RC"
case "$OUT" in *"no such backup"* ) ok "reports missing backup" ;; *) no "missing backup msg: $OUT" ;; esac

echo "=== test-restore-backup: direct run with no backups fails ==="
EMPTY_HOME="$WORK/emptyhome"
mkdir -p "$EMPTY_HOME/.config"
OUT="$(PATH="$WORK/bin:$PATH" HOME="$EMPTY_HOME" bash "$ROOT/scripts/restore-backup.sh" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "fails when no backups exist" || no "should fail with no backups rc=$RC"
case "$OUT" in *"No backups found under ~/.config/kde-backups/ - nothing to restore."* ) ok "reports no backups found" ;; *) no "no-backups msg: [$OUT]" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-restore-backup: ALL PASS"; exit 0; fi
echo "test-restore-backup: $fails FAILURE(S)"
exit 1
