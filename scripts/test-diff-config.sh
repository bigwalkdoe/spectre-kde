#!/usr/bin/env bash
# Tests for scripts/diff-config.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

REPO="$WORK/repo"
mkdir -p "$REPO/scripts" "$REPO/config"
cp "$ROOT/scripts/diff-config.sh" "$REPO/scripts/diff-config.sh"
chmod +x "$REPO/scripts/diff-config.sh"

HOME_DIR="$WORK/home"
mkdir -p "$HOME_DIR/.config"

run_diff(){ HOME="$HOME_DIR" bash "$REPO/scripts/diff-config.sh" "$@"; }

echo "=== test-diff-config: identical file ==="
cat > "$REPO/config/applied-kdeglobals.conf" <<'EOF'
[General]
ColorScheme=Orchis
EOF
cp "$REPO/config/applied-kdeglobals.conf" "$HOME_DIR/.config/kdeglobals"
OUT="$(run_diff kdeglobals 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 for identical file" || no "exit $RC: $OUT"
case "$OUT" in *"=== kdeglobals ==="*Identical* ) ok "reports identical" ;; *) no "missing identical report: $OUT" ;; esac

echo "=== test-diff-config: different file shows diff ==="
cat > "$HOME_DIR/.config/kdeglobals" <<'EOF'
[General]
ColorScheme=OrchisDark
EOF
OUT="$(run_diff kdeglobals 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "exits non-zero for different file" || no "expected non-zero exit, got $RC: $OUT"
case "$OUT" in *"Different"* ) ok "reports different" ;; *) no "missing different report: $OUT" ;; esac
case "$OUT" in *"-ColorScheme=Orchis"*"+ColorScheme=OrchisDark"* ) ok "includes unified diff excerpt" ;; *) no "missing diff excerpt: $OUT" ;; esac
# restore to identical state for later overview test
cp "$REPO/config/applied-kdeglobals.conf" "$HOME_DIR/.config/kdeglobals"

echo "=== test-diff-config: live exists but no repo snapshot ==="
echo "x=1" > "$HOME_DIR/.config/plasmarc"
OUT="$(run_diff plasmarc 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 when only live exists" || no "exit $RC: $OUT"
case "$OUT" in *"Live file exists (no repo snapshot)"* ) ok "reports live-only state" ;; *) no "missing live-only report: $OUT" ;; esac

echo "=== test-diff-config: repo snapshot but live missing ==="
cat > "$REPO/config/applied-kwinrc.conf" <<'EOF'
[Plugins]
blurEnabled=true
EOF
rm -f "$HOME_DIR/.config/kwinrc"
OUT="$(run_diff kwinrc 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 when live missing" || no "exit $RC: $OUT"
case "$OUT" in *"Live file missing (repo has snapshot)"* ) ok "reports missing live file" ;; *) no "missing live-missing report: $OUT" ;; esac

echo "=== test-diff-config: special-case appletsrc snapshot name ==="
cat > "$REPO/config/applied-appletsrc.conf" <<'EOF'
[Containments][1]
plugin=org.kde.desktopcontainment
EOF
cp "$REPO/config/applied-appletsrc.conf" "$HOME_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc"
OUT="$(run_diff plasma-org.kde.plasma.desktop-appletsrc 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 for appletsrc special case" || no "exit $RC: $OUT"
case "$OUT" in *"Identical"* ) ok "matches applied-appletsrc.conf snapshot" ;; *) no "appletsrc special case failed: $OUT" ;; esac

echo "=== test-diff-config: no args runs overview ==="
OUT="$(run_diff 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 for overview when no differences found" || no "overview exit $RC: $OUT"
case "$OUT" in *"spectre-kde Config Diff (live vs repo snapshots)"* ) ok "prints overview header" ;; *) no "missing overview header: $OUT" ;; esac
case "$OUT" in *"Run with a filename to see full diff for one file"* ) ok "prints overview hint" ;; *) no "missing overview hint: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-diff-config: ALL PASS"; exit 0; fi
echo "test-diff-config: $fails FAILURE(S)"
exit 1
