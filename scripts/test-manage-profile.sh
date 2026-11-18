#!/usr/bin/env bash
# Tests for scripts/export-profile.sh, scripts/import-profile.sh, scripts/manage-profile.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

setup_repo(){
  local repo="$1"
  mkdir -p "$repo/scripts" "$repo/profiles"
  cp "$ROOT/scripts/export-profile.sh" "$repo/scripts/"
  cp "$ROOT/scripts/import-profile.sh" "$repo/scripts/"
  cp "$ROOT/scripts/manage-profile.sh" "$repo/scripts/"
  chmod +x "$repo/scripts/export-profile.sh" "$repo/scripts/import-profile.sh" "$repo/scripts/manage-profile.sh"
  # seed current config inputs
  cat > "$repo/scripts/dock-launchers.list" <<'EOF'
org.kde.dolphin.desktop
EOF
  cat > "$repo/scripts/dock-config" <<'EOF'
DOCK_POSITION=bottom
DOCK_CENTERED=true
EOF
  cat > "$repo/scripts/topbar-config" <<'EOF'
TOPBAR_SHOW_NETSPEED=true
EOF
  cat > "$repo/scripts/tray-config.js" <<'EOF'
// tray
EOF
  cat > "$repo/scripts/autostart.list" <<'EOF'
# none
EOF
  echo "light-marker" > "$repo/.applied-light"
}

echo "=== test-manage-profile: export-profile creates profile snapshot ==="
REPO="$WORK/repo1"; setup_repo "$REPO"
OUT="$(bash "$REPO/scripts/export-profile.sh" '../bad' 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "export-profile rejects invalid profile name" || no "export-profile should reject invalid profile name"
OUT="$(bash "$REPO/scripts/export-profile.sh" work 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "export-profile exits 0" || no "export-profile exit $RC: $OUT"
[ -d "$REPO/profiles/work" ] && ok "creates profile directory" || no "missing profile directory"
[ -f "$REPO/profiles/work/dock-launchers.list" ] && ok "exports dock launchers" || no "missing dock launchers"
[ -f "$REPO/profiles/work/dock-config" ] && ok "exports dock config" || no "missing dock config"
[ -f "$REPO/profiles/work/topbar-config" ] && ok "exports topbar config" || no "missing topbar config"
[ -f "$REPO/profiles/work/tray-config.js" ] && ok "exports tray config" || no "missing tray config"
[ -f "$REPO/profiles/work/autostart.list" ] && ok "exports autostart list" || no "missing autostart list"
[ -f "$REPO/profiles/work/.applied-light" ] && ok "exports applied marker when present" || no "missing applied marker"
[ -f "$REPO/profiles/work/profile-info.txt" ] && ok "writes profile-info.txt" || no "missing profile-info.txt"
grep -q '^Profile: work$' "$REPO/profiles/work/profile-info.txt" && ok "profile-info contains profile name" || no "profile-info missing name"
case "$OUT" in *"Profile exported to:"*work*) ok "prints export destination" ;; *) no "missing export message: $OUT" ;; esac

echo "=== test-manage-profile: import-profile copies files and reports ==="
REPO="$WORK/repo2"; setup_repo "$REPO"
bash "$REPO/scripts/export-profile.sh" work >/dev/null 2>&1
# mutate current config to verify import overwrites
echo "changed" > "$REPO/scripts/dock-launchers.list"
echo "changed" > "$REPO/scripts/topbar-config"
OUT="$(bash "$REPO/scripts/import-profile.sh" work 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "import-profile exits 0" || no "import-profile exit $RC: $OUT"
[ "$(cat "$REPO/scripts/dock-launchers.list")" = "org.kde.dolphin.desktop" ] && ok "imports dock launchers" || no "dock launchers not restored"
[ "$(grep -c 'TOPBAR_SHOW_NETSPEED=true' "$REPO/scripts/topbar-config")" -eq 1 ] && ok "imports topbar config" || no "topbar config not restored"
case "$OUT" in *"Imported dock launchers"*"Imported top bar config"* ) ok "reports imported components" ;; *) no "missing import report: $OUT" ;; esac
case "$OUT" in *"Profile imported. Run './apply.sh --light' or './apply.sh --dark' to apply."*) ok "prints apply hint" ;; *) no "missing apply hint: $OUT" ;; esac

echo "=== test-manage-profile: import-profile usage and missing profile errors ==="
OUT="$(bash "$REPO/scripts/import-profile.sh" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "import-profile fails without name" || no "should fail without name"
case "$OUT" in *"Usage: "*"<profile-name>"* ) ok "prints usage when name missing" ;; *) no "missing usage: $OUT" ;; esac
OUT="$(bash "$REPO/scripts/import-profile.sh" nope 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "import-profile fails for missing profile" || no "should fail for missing profile"
case "$OUT" in *"Error: Profile not found:"* ) ok "reports missing profile" ;; *) no "missing not-found message: $OUT" ;; esac
OUT="$(bash "$REPO/scripts/import-profile.sh" '../bad' 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "import-profile rejects invalid profile name" || no "should reject invalid profile name"

echo "=== test-manage-profile: manage-profile list/import/export/apply/help ==="
REPO="$WORK/repo3"; setup_repo "$REPO"
bash "$REPO/scripts/export-profile.sh" work >/dev/null 2>&1
# add description to profile-info for list formatting
printf '\nDescription: Work layout\n' >> "$REPO/profiles/work/profile-info.txt"
OUT="$(bash "$REPO/scripts/manage-profile.sh" list 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile list exits 0" || no "list exit $RC: $OUT"
case "$OUT" in *"Available profiles:"*"work"*"Work layout"* ) ok "lists profiles with description" ;; *) no "list output unexpected: $OUT" ;; esac
OUT="$(bash "$REPO/scripts/manage-profile.sh" 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile defaults to list" || no "default command exit $RC"
case "$OUT" in *"Available profiles:"* ) ok "default command lists profiles" ;; *) no "default output: $OUT" ;; esac

echo "changed" > "$REPO/scripts/dock-config"
OUT="$(bash "$REPO/scripts/manage-profile.sh" import work 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile import exits 0" || no "manage-profile import exit $RC: $OUT"
grep -q '^DOCK_CENTERED=true$' "$REPO/scripts/dock-config" && ok "manage-profile import delegates correctly" || no "manage-profile import did not restore config"

rm -rf "$REPO/profiles/exported"
OUT="$(bash "$REPO/scripts/manage-profile.sh" export exported 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile export exits 0" || no "manage-profile export exit $RC: $OUT"
[ -d "$REPO/profiles/exported" ] && ok "manage-profile export creates profile" || no "manage-profile export missing profile"

OUT="$(bash "$REPO/scripts/manage-profile.sh" help 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile help exits 0" || no "help exit $RC"
case "$OUT" in *"spectre-kde Profile Manager"*list*import*export*apply*show* ) ok "help shows commands including show" ;; *) no "help output: $OUT" ;; esac

OUT="$(bash "$REPO/scripts/manage-profile.sh" show work 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile show exits 0" || no "show exit $RC: $OUT"
case "$OUT" in *"Profile: work"* ) ok "show displays profile name/info" ;; *) no "show missing profile info: $OUT" ;; esac
case "$OUT" in *"dock-launchers.list"*topbar-config*tray-config.js* ) ok "show lists included files" ;; *) no "show missing file list: $OUT" ;; esac
OUT="$(bash "$REPO/scripts/manage-profile.sh" show nope 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "manage-profile show fails for missing profile" || no "show should fail for missing profile"

OUT="$(bash "$REPO/scripts/manage-profile.sh" nope 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "manage-profile rejects unknown command" || no "unknown command should fail"
case "$OUT" in *"Unknown command: nope"* ) ok "reports unknown command" ;; *) no "unknown command msg: $OUT" ;; esac

# apply: stub quick-update.sh to avoid real side effects
cat > "$REPO/quick-update.sh" <<'EOF'
#!/usr/bin/env bash
echo "QUICK_UPDATE_RAN"
EOF
chmod +x "$REPO/quick-update.sh"
echo "changed" > "$REPO/scripts/topbar-config"
OUT="$(bash "$REPO/scripts/manage-profile.sh" apply work 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "manage-profile apply exits 0 with stubbed quick-update" || no "apply exit $RC: $OUT"
grep -q '^TOPBAR_SHOW_NETSPEED=true$' "$REPO/scripts/topbar-config" && ok "manage-profile apply imports profile" || no "apply did not import"
case "$OUT" in *"QUICK_UPDATE_RAN"* ) ok "manage-profile apply runs quick-update" ;; *) no "apply missing quick-update: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-profile: ALL PASS"; exit 0; fi
echo "test-manage-profile: $fails FAILURE(S)"
exit 1
