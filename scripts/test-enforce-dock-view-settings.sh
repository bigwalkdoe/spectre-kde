#!/usr/bin/env bash
# Tests for scripts/enforce-dock-view-settings.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/repo/scripts" "$WORK/repo/scripts/lib" "$WORK/home/.config"
cp "$ROOT/scripts/enforce-dock-view-settings.sh" "$WORK/repo/scripts/enforce-dock-view-settings.sh"
cp "$ROOT/scripts/lib/plasma.sh" "$WORK/repo/scripts/lib/plasma.sh"
chmod +x "$WORK/repo/scripts/enforce-dock-view-settings.sh"

cat > "$WORK/repo/scripts/dock-config" <<'EOF'
DOCK_FIT_TO_CONTENT=true
DOCK_CENTERED=false
DOCK_FLOATING=true
EOF

cat > "$WORK/repo/scripts/set-dock-view-settings.sh" <<'STUB'
#!/usr/bin/env bash
echo "SET $*" >> "$HOME/.set.log"
exit 0
STUB
chmod +x "$WORK/repo/scripts/set-dock-view-settings.sh"

cat > "$WORK/home/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][10]
plugin=org.kde.panel

[Containments][10][Applets][101]
plugin=org.kde.plasma.appmenu

[Containments][20]
plugin=org.kde.panel

[Containments][20][Applets][201]
plugin=org.kde.plasma.kickoff

[Containments][20][Applets][202]
plugin=org.kde.plasma.icontasks

[Containments][20][Applets][203]
plugin=org.kde.plasma.trash
RC

run_enf(){
  HOME="$WORK/home" bash "$WORK/repo/scripts/enforce-dock-view-settings.sh" "$@"
}

echo "=== test-enforce-dock-view-settings: auto-detects dock panel from icontasks ==="
: > "$WORK/home/.set.log"
OUT="$(run_enf 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0" || no "exit $RC: $OUT"
grep -q '^SET 20 true false true$' "$WORK/home/.set.log" && ok "applies dock-config settings to detected dock panel" || no "log: $(cat "$WORK/home/.set.log" 2>/dev/null)"

echo "=== test-enforce-dock-view-settings: explicit panel id overrides detection ==="
: > "$WORK/home/.set.log"
OUT="$(run_enf 99 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 with explicit panel id" || no "exit $RC: $OUT"
grep -q '^SET 99 true false true$' "$WORK/home/.set.log" && ok "uses explicit panel id" || no "log: $(cat "$WORK/home/.set.log" 2>/dev/null)"

echo "=== test-enforce-dock-view-settings: fails when dock panel cannot be detected ==="
cat > "$WORK/home/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][10]
plugin=org.kde.panel

[Containments][10][Applets][101]
plugin=org.kde.plasma.appmenu
RC
: > "$WORK/home/.set.log"
OUT="$(run_enf 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "fails when no icontasks dock found" || no "should fail rc=$RC"
case "$OUT" in *"could not detect dock panel"*|*"dock panel"* ) ok "reports detection failure" ;; *) no "msg: $OUT" ;; esac
[ ! -s "$WORK/home/.set.log" ] && ok "does not apply settings when detection fails" || no "unexpected apply: $(cat "$WORK/home/.set.log")"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-enforce-dock-view-settings: ALL PASS"; exit 0; fi
echo "test-enforce-dock-view-settings: $fails FAILURE(S)"
exit 1
