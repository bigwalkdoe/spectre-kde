#!/usr/bin/env bash
# Tests for scripts/manage-nightlight.sh.
#
# Stubs kreadconfig6/kwriteconfig6/qdbus6 so kwinrc is never mutated.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# --- stub config tools ---
mkdir -p "$WORK/bin"
KWINRC="$WORK/.config/kwinrc"
mkdir -p "$(dirname "$KWINRC")"
touch "$KWINRC"

printf '#!/bin/sh\n# stub kreadconfig6: --file <file> --group <group> --key <key>\nfile=""; key=""\nwhile [ $# -gt 0 ]; do\n  case "$1" in\n    --file) shift; file="$1" ;;\n    --key) shift; key="$1" ;;\n    *) ;; esac; shift\ndone\ngrep "^${key}=" "$file" 2>/dev/null | cut -d= -f2- || true\n' > "$WORK/bin/kreadconfig6"
chmod +x "$WORK/bin/kreadconfig6"

printf '#!/bin/sh\n# stub kwriteconfig6: --file <file> --key <key> <value>\n# manage-nightlight.sh passes --file kwinrc (bare name), map to $HOME/.config/kwinrc\nfile=""; key=""; val=""\nwhile [ $# -gt 0 ]; do\n  case "$1" in\n    --file) shift; [ "$1" = "kwinrc" ] && file=\"$HOME/.config/kwinrc\" || file=\"$1\" ;;\n    --key) shift; key="$1" ;;\n    *) val="$1" ;;\n  esac; shift\ndone\ntmp=\"$(mktemp)\"\n[ -f \"$file\" ] && grep -v \"^${key}=\" \"$file\" > \"$tmp\"\necho \"${key}=${val}\" >> \"$tmp\"\nmv \"$tmp\" \"$file\"\n' > "$WORK/bin/kwriteconfig6"
chmod +x "$WORK/bin/kwriteconfig6"

printf '#!/bin/sh\n# stub qdbus6 - no-op success\nexit 0\n' > "$WORK/bin/qdbus6"
chmod +x "$WORK/bin/qdbus6"

run_nightlight(){
  PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$ROOT/scripts/manage-nightlight.sh" "$@"
}

echo "=== test-manage-nightlight: status ==="
OUT="$(run_nightlight status)"
case "$OUT" in
  *"Night Color Status"* ) ok "status prints header" ;;
  *) no "status missing header: $OUT" ;;
esac
case "$OUT" in
  *"Enabled: false"* ) ok "status shows Enabled=false when inactive" ;;
  *) no "status missing Enabled=false: $OUT" ;;
esac

echo "=== test-manage-nightlight: enable ==="
OUT="$(run_nightlight enable Automatic 4500)"
case "$OUT" in
  *"Night Color enabled"* ) ok "enable reports success" ;;
  *) no "enable missing success: $OUT" ;;
esac
ACTIVE="$(grep '^Active=' "$KWINRC" || true)"
[ "$ACTIVE" = "Active=true" ] && ok "enable writes Active=true" || no "enable did not write Active=true (got: $ACTIVE)"
MODE="$(grep '^Mode=' "$KWINRC" || true)"
[ "$MODE" = "Mode=Automatic" ] && ok "enable writes Mode=Automatic" || no "enable did not write Mode=Automatic (got: $MODE)"
TEMP="$(grep '^NightTemperature=' "$KWINRC" || true)"
[ "$TEMP" = "NightTemperature=4500" ] && ok "enable writes NightTemperature=4500" || no "enable did not write NightTemperature=4500 (got: $TEMP)"

echo "=== test-manage-nightlight: disable ==="
OUT="$(run_nightlight disable)"
case "$OUT" in
  *"Night Color disabled"* ) ok "disable reports success" ;;
  *) no "disable missing success: $OUT" ;;
esac
ACTIVE="$(grep '^Active=' "$KWINRC" || true)"
[ "$ACTIVE" = "Active=false" ] && ok "disable writes Active=false" || no "disable did not write Active=false (got: $ACTIVE)"

echo "=== test-manage-nightlight: schedule ==="
OUT="$(run_nightlight schedule 22:00 06:00)"
case "$OUT" in
  *"Schedule set"* ) ok "schedule reports success" ;;
  *) no "schedule missing success: $OUT" ;;
esac
MODE="$(grep '^Mode=' "$KWINRC" | tail -1 || true)"
[ "$MODE" = "Mode=Timings" ] && ok "schedule writes Mode=Timings" || no "schedule did not write Mode=Timings (got: $MODE)"
BEGIN="$(grep '^EveningBeginFixed=' "$KWINRC" || true)"
[ "$BEGIN" = "EveningBeginFixed=22:00" ] && ok "schedule writes EveningBeginFixed=22:00" || no "schedule did not write EveningBeginFixed (got: $BEGIN)"
END="$(grep '^MorningBeginFixed=' "$KWINRC" || true)"
[ "$END" = "MorningBeginFixed=06:00" ] && ok "schedule writes MorningBeginFixed=06:00" || no "schedule did not write MorningBeginFixed (got: $END)"

echo "=== test-manage-nightlight: default is status (not usage) ==="
OUT="$(run_nightlight)"
case "$OUT" in
  *"Night Color Status"* ) ok "no-args runs status (default)" ;;
  *) no "no-args should default to status: $OUT" ;;
esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-manage-nightlight: ALL PASS"
  exit 0
fi
echo "test-manage-nightlight: $fails FAILURE(S)"
exit 1
