#!/usr/bin/env bash
# Tests for scripts/clean-plasmashellrc.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/.config"
cp "$ROOT/scripts/clean-plasmashellrc.sh" "$WORK/clean-plasmashellrc.sh"
chmod +x "$WORK/clean-plasmashellrc.sh"

run_clean(){ HOME="$WORK" bash "$WORK/clean-plasmashellrc.sh"; }

echo "=== test-clean-plasmashellrc: no-op when files missing ==="
OUT="$(run_clean 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 when plasmashellrc missing" || no "exit $RC when plasmashellrc missing"

echo "=== test-clean-plasmashellrc: removes stale panel sections and keeps live ones ==="
cat > "$WORK/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][100]
plugin=org.kde.panel

[Containments][200]
plugin=org.kde.panel

[Containments][300]
plugin=org.kde.desktopcontainment
RC
cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 100]
alignment=132
panelVisibility=2

[PlasmaViews][Panel 100][Defaults]
thickness=44

[PlasmaViews][Panel 999]
alignment=132
panelVisibility=2

[PlasmaViews][Panel 200]
alignment=132

[Updates]
performed=/some/update
RC
OUT="$(run_clean 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 on clean" || no "clean exit $RC: $OUT"
case "$OUT" in *"kept panels: 100 200"*) ok "reports kept panels" ;; *) no "missing kept panels report: $OUT" ;; esac
grep -q '^\[PlasmaViews\]\[Panel 100\]$' "$WORK/.config/plasmashellrc" && ok "keeps live panel 100" || no "lost panel 100"
grep -q '^\[PlasmaViews\]\[Panel 100\]\[Defaults\]$' "$WORK/.config/plasmashellrc" && ok "keeps live panel defaults" || no "lost panel defaults"
grep -q '^\[PlasmaViews\]\[Panel 200\]$' "$WORK/.config/plasmashellrc" && ok "keeps live panel 200" || no "lost panel 200"
if grep -q '^\[PlasmaViews\]\[Panel 999\]' "$WORK/.config/plasmashellrc"; then no "stale panel 999 not removed"; else ok "removes stale panel 999"; fi
grep -q '^\[Updates\]$' "$WORK/.config/plasmashellrc" && ok "preserves unrelated sections" || no "lost unrelated section"
grep -q '^performed=/some/update$' "$WORK/.config/plasmashellrc" && ok "preserves unrelated section content" || no "lost unrelated content"

echo "=== test-clean-plasmashellrc: idempotent ==="
BEFORE="$(cat "$WORK/.config/plasmashellrc")"
run_clean >/dev/null 2>&1
AFTER="$(cat "$WORK/.config/plasmashellrc")"
[ "$BEFORE" = "$AFTER" ] && ok "idempotent when already clean" || no "changed file on second run"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-clean-plasmashellrc: ALL PASS"; exit 0; fi
echo "test-clean-plasmashellrc: $fails FAILURE(S)"
exit 1
