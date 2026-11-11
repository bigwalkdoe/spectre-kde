#!/usr/bin/env bash
# Tests for scripts/clean-backups.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

HOME="$WORK/home"
BACKUP_DIR="$HOME/.config/kde-backups"
mkdir -p "$BACKUP_DIR"

run_clean(){
  HOME="$HOME" bash "$ROOT/scripts/clean-backups.sh" "$@"
}

count_backups(){
  find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l
}

echo "=== test-clean-backups: nothing to do ==="
out="$(run_clean 5 2>&1 || true)"
[ "$(count_backups)" -eq 0 ] && ok "no backups dir contents remains empty" || no "expected zero backups"
printf '%s\n' "$out" | grep -q "Nothing to clean" && ok "reports nothing to clean when under limit" \
  || no "should report nothing to clean when under limit" "$out"

echo "=== test-clean-backups: keeps newest N by mtime ==="
rm -rf "$BACKUP_DIR" && mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/b1" "$BACKUP_DIR/b2" "$BACKUP_DIR/b3" "$BACKUP_DIR/b4"
touch -t 202601010101 "$BACKUP_DIR/b1"
touch -t 202601020101 "$BACKUP_DIR/b2"
touch -t 202601030101 "$BACKUP_DIR/b3"
touch -t 202601040101 "$BACKUP_DIR/b4"
out="$(run_clean 2 2>&1)"
[ "$(count_backups)" -eq 2 ] && ok "keeps requested number of backups" || no "expected 2 backups to remain" "count=$(count_backups)"
[ ! -d "$BACKUP_DIR/b1" ] && [ ! -d "$BACKUP_DIR/b2" ] && ok "removes oldest backups" \
  || no "should remove oldest backups" "$(ls -1 "$BACKUP_DIR" 2>&1 || true)"
[ -d "$BACKUP_DIR/b3" ] && [ -d "$BACKUP_DIR/b4" ] && ok "retains newest backups" \
  || no "should retain newest backups" "$(ls -1 "$BACKUP_DIR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q "Removing 2 old backup(s)" && ok "reports removal count" \
  || no "should report removal count" "$out"

echo "=== test-clean-backups: missing backup dir ==="
rm -rf "$HOME/.config"
out="$(run_clean 10 2>&1)"
printf '%s\n' "$out" | grep -q "No backups directory found" && ok "handles missing backups directory" \
  || no "should handle missing backups directory" "$out"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-clean-backups: ALL PASS"
  exit 0
fi
echo "test-clean-backups: $fails FAILURE(S)"
exit 1
