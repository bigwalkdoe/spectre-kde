#!/usr/bin/env bash
# Tests for scripts/manage-power.sh (status only).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/.config"
cp "$ROOT/scripts/manage-power.sh" "$WORK/scripts/manage-power.sh"
chmod +x "$WORK/scripts/manage-power.sh"

# stub powerprofilesctl
mkdir -p "$WORK/bin"
cat > "$WORK/bin/powerprofilesctl" <<'EOF'
#!/bin/sh
case "$1" in
  get) echo "balanced" ;;
  list) echo "balanced performance power-saver" ;;
  set) exit 0 ;;
esac
EOF
chmod +x "$WORK/bin/powerprofilesctl"

run(){ PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts/manage-power.sh" "$@"; }

echo "=== test-manage-power: status ==="
OUT="$(run status)"
case "$OUT" in *"balanced"*) ok "status shows balanced" ;; *) no "status missing balanced: $OUT" ;; esac

echo "=== test-manage-power: set profile ==="
OUT="$(run performance)"
case "$OUT" in *"Power profile set to performance"*|*"set to: performance"*) ok "set performance" ;; *) no "set failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-power: ALL PASS"; exit 0; fi
echo "test-manage-power: $fails FAILURE(S)"
exit 1