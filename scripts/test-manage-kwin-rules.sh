#!/usr/bin/env bash
# Tests for scripts/manage-kwin-rules.sh (list/show/add/remove).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/config"
cp "$ROOT/scripts/manage-kwin-rules.sh" "$WORK/scripts/manage-kwin-rules.sh"
cp "$ROOT/config/applied-kwinrulesrc.conf" "$WORK/config/applied-kwinrulesrc.conf"
chmod +x "$WORK/scripts/manage-kwin-rules.sh"

run(){ HOME="$WORK" bash "$WORK/scripts/manage-kwin-rules.sh" "$@"; }
CONF="$WORK/config/applied-kwinrulesrc.conf"

echo "=== test-manage-kwin-rules: list ==="
OUT="$(run list)"
case "$OUT" in *"Konsole - borderless"*) ok "list shows Konsole rule" ;; *) no "list missing Konsole: $OUT" ;; esac
case "$OUT" in *"Firefox - desktop 2"*) ok "list shows Firefox rule" ;; *) no "list missing Firefox: $OUT" ;; esac
case "$OUT" in *"Spotify - keep above"*) ok "list shows Spotify rule" ;; *) no "list missing Spotify: $OUT" ;; esac

echo "=== test-manage-kwin-rules: show ==="
OUT="$(run show 'Konsole - borderless')"
case "$OUT" in *"Konsole - borderless"*) ok "show works" ;; *) no "show failed: $OUT" ;; esac
case "$OUT" in *"decorationpolicyrule=2"*) ok "show includes native action rule" ;; *) no "show missing decorationpolicyrule: $OUT" ;; esac

echo "=== test-manage-kwin-rules: native format ==="
grep -q '^\[General\]$' "$CONF" && ok "[General] section present" || no "[General] section missing"
grep -q '^Order=1,2,3,4,5,6,7$' "$CONF" && ok "Order=1..7 present" || no "Order list missing"
grep -q '^desktops=@DESKTOP_2@$' "$CONF" && ok "desktop placeholder present" || no "desktop placeholder missing"
grep -q '^above=true$' "$CONF" && ok "above action present" || no "above action missing"

echo "=== test-manage-kwin-rules: add ==="
OUT="$(run add 'Test Rule' testapp 4 true false)"
case "$OUT" in *"Added"*"Test Rule"*) ok "add reports success" ;; *) no "add failed: $OUT" ;; esac
grep -q '^Description=Test Rule$' "$CONF" && ok "add writes Description" || no "add missing Description"
grep -q '^desktops=@DESKTOP_4@$' "$CONF" && ok "add writes desktop placeholder" || no "add missing desktop placeholder"
grep -q '^desktopsrule=2$' "$CONF" && ok "add writes desktopsrule" || no "add missing desktopsrule"
grep -q '^decorationpolicy=none$' "$CONF" && ok "add writes decorationpolicy" || no "add missing decorationpolicy"
grep -q '^Order=1,2,3,4,5,6,7,8$' "$CONF" && ok "add updates Order" || no "add did not update Order"

echo "=== test-manage-kwin-rules: remove ==="
OUT="$(run remove 'Test Rule')"
case "$OUT" in *"Removed"*) ok "remove reports success" ;; *) no "remove failed: $OUT" ;; esac
grep -q '^Description=Test Rule$' "$CONF" && no "remove left Description behind" || ok "remove deletes rule"

echo "=== test-manage-kwin-rules: Order consistency after remove ==="
ORDER="$(grep '^Order=' "$CONF" | cut -d= -f2)"
NSEC="$(grep -c -E '^\[[0-9]+\]$' "$CONF")"
NORDER="$(printf '%s' "$ORDER" | tr ',' '\n' | grep -c .)"
if [ "$NSEC" = "$NORDER" ]; then
  ok "Order items ($NORDER) match sections ($NSEC)"
else
  no "Order items ($NORDER) != sections ($NSEC)"
fi

echo "=== test-manage-kwin-rules: remove nonexistent ==="
OUT="$(run remove 'No Such Rule' 2>&1)" || true
case "$OUT" in *"not found"*) ok "remove rejects unknown rule" ;; *) no "remove accepted unknown rule: $OUT" ;; esac

echo "=== test-manage-kwin-rules: show by number ==="
OUT="$(run show 1)"
case "$OUT" in *"Konsole - borderless"*) ok "show by number works" ;; *) no "show by number failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-kwin-rules: ALL PASS"; exit 0; fi
echo "test-manage-kwin-rules: $fails FAILURE(S)"
exit 1
