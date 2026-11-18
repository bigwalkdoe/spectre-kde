#!/usr/bin/env bash
# Tests for scripts/resolve-launchers.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/resolve-launchers.sh" "$WORK/scripts/resolve-launchers.sh"
chmod +x "$WORK/scripts/resolve-launchers.sh"

# Stub desktop-file-path.sh: succeeds for ids listed in $WORK/installed.txt
cat > "$WORK/scripts/desktop-file-path.sh" <<'STUB'
#!/usr/bin/env bash
id="$1"
if [ -f "$(dirname "$0")/../installed.txt" ] && grep -qx "$id" "$(dirname "$0")/../installed.txt"; then
  echo "/usr/share/applications/$id"
  exit 0
fi
exit 1
STUB
chmod +x "$WORK/scripts/desktop-file-path.sh"

run_resolve(){
  local list="$1"; shift
  bash "$WORK/scripts/resolve-launchers.sh" "$list" "$@"
}

echo "=== test-resolve-launchers: resolves installed entries, trims, skips comments/blanks ==="
cat > "$WORK/installed.txt" <<'EOF'
org.kde.dolphin.desktop
com.microsoft.VSCode.desktop
EOF
cat > "$WORK/list.txt" <<'EOF'
# comment

  org.kde.dolphin.desktop   # Files
org.missing.desktop
com.microsoft.VSCode.desktop|code.desktop
EOF
OUT_FILE="$WORK/out.txt"; ERR_FILE="$WORK/err.txt"
run_resolve "$WORK/list.txt" >"$OUT_FILE" 2>"$ERR_FILE"; RC=$?
OUT="$(cat "$OUT_FILE")"; ERR="$(cat "$ERR_FILE")"
[ "$RC" -eq 0 ] && ok "exits 0 when some entries resolve" || no "exit $RC"
[ "$OUT" = "applications:org.kde.dolphin.desktop,applications:com.microsoft.VSCode.desktop" ] && ok "emits resolved launchers in order" || no "stdout: [$OUT]"
case "$ERR" in *"not installed, skipping 'org.missing.desktop'"*) ok "reports skipped missing entry" ;; *) no "stderr missing skip: [$ERR]" ;; esac
case "$ERR" in *"2 pinned, 1 skipped as not installed"*) ok "reports summary counts" ;; *) no "stderr missing summary: [$ERR]" ;; esac

echo "=== test-resolve-launchers: uses first installed candidate in fallback list ==="
cat > "$WORK/installed.txt" <<'EOF'
org.real.App.desktop
EOF
cat > "$WORK/list2.txt" <<'EOF'
org.alt.desktop|org.real.App.desktop|other.desktop
EOF
OUT="$(run_resolve "$WORK/list2.txt" 2>/dev/null)"; RC=$?
[ "$RC" -eq 0 ] && ok "fallback resolves" || no "fallback exit $RC"
[ "$OUT" = "applications:org.real.App.desktop" ] && ok "picks first installed fallback candidate" || no "fallback stdout: [$OUT]"

echo "=== test-resolve-launchers: fails when list missing ==="
OUT="$(run_resolve "$WORK/nope.txt" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "fails on missing list" || no "should fail on missing list"
case "$OUT" in *"no such list"*) ok "reports missing list" ;; *) no "missing-list msg: $OUT" ;; esac

echo "=== test-resolve-launchers: fails when nothing resolves ==="
cat > "$WORK/installed.txt" <<'EOF'
EOF
cat > "$WORK/empty.txt" <<'EOF'
# only comments
org.none.desktop
EOF
ERR_FILE="$WORK/err2.txt"
run_resolve "$WORK/empty.txt" >/dev/null 2>"$ERR_FILE"; RC=$?
ERR="$(cat "$ERR_FILE")"
[ "$RC" -ne 0 ] && ok "fails when nothing resolves" || no "should fail when empty result rc=$RC"
case "$ERR" in *"nothing in "*"resolved to an installed desktop file"*) ok "reports empty resolution error" ;; *) no "empty error msg: [$ERR]" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-resolve-launchers: ALL PASS"; exit 0; fi
echo "test-resolve-launchers: $fails FAILURE(S)"
exit 1
