#!/usr/bin/env bash
# Tests for scripts/manage-fonts.sh (info/exclude only).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/.config/fontconfig" "$WORK/.local/share/fonts"
cp "$ROOT/scripts/manage-fonts.sh" "$WORK/scripts/manage-fonts.sh"
chmod +x "$WORK/scripts/manage-fonts.sh"

# stub fc-list/fc-match
mkdir -p "$WORK/bin"
cat > "$WORK/bin/fc-list" <<'EOF'
#!/bin/sh
echo "Noto Sans"
EOF
cat > "$WORK/bin/fc-match" <<'EOF'
#!/bin/sh
echo "NotoSans-Regular.ttf: ... "
EOF
chmod +x "$WORK/bin/fc-list" "$WORK/bin/fc-match"

run(){ PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts/manage-fonts.sh" "$@"; }

echo "=== test-manage-fonts: info ==="
OUT="$(run info)"
case "$OUT" in *"Font system information:"*) ok "info works" ;; *) no "info failed: $OUT" ;; esac
case "$OUT" in *"fonts.conf: not found"*) ok "info reports missing conf" ;; *) no "info missing conf msg: $OUT" ;; esac

echo "=== test-manage-fonts: exclude (no conf) ==="
OUT="$(run exclude)"
case "$OUT" in *"No font exclusions"*|*"No fontconfig config"*) ok "exclude handles missing conf" ;; *) no "exclude failed: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-fonts: ALL PASS"; exit 0; fi
echo "test-manage-fonts: $fails FAILURE(S)"
exit 1