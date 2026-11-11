#!/usr/bin/env bash
# Tests for scripts/desktop-file-path.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# shellcheck source=scripts/desktop-file-path.sh
. "$ROOT/scripts/desktop-file-path.sh"

export XDG_DATA_HOME="$WORK/data"
export XDG_DATA_DIRS="$WORK/sys1:$WORK/sys2"
HOME="$WORK/home"

echo "=== test-desktop-file-path: resolves installed desktop file ==="
mkdir -p "$XDG_DATA_HOME/applications"
cat > "$XDG_DATA_HOME/applications/org.kde.dolphin.desktop" <<'EOF'
[Desktop Entry]
Name=Dolphin
Type=Application
EOF
out="$(desktop_file_path org.kde.dolphin.desktop || true)"
case "$out" in
  "$XDG_DATA_HOME/applications/org.kde.dolphin.desktop") ok "resolves desktop file in XDG_DATA_HOME applications dir" ;;
  *) no "should resolve desktop file in XDG_DATA_HOME applications dir" "got: ${out:-<empty>}" ;;
esac

echo "=== test-desktop-file-path: resolves from XDG_DATA_DIRS ==="
mkdir -p "$WORK/sys1/applications"
: > "$WORK/sys1/applications/firefox.desktop"
out="$(XDG_DATA_HOME="$WORK/empty-home" desktop_file_path firefox.desktop || true)"
case "$out" in
  "$WORK/sys1/applications/firefox.desktop") ok "resolves desktop file from XDG_DATA_DIRS applications dir" ;;
  *) no "should resolve desktop file from XDG_DATA_DIRS applications dir" "got: ${out:-<empty>}" ;;
esac

echo "=== test-desktop-file-path: missing or invalid ids ==="
if desktop_file_path does-not-exist.desktop >/dev/null 2>&1; then
  no "missing desktop id should return failure" "got exit 0"
else
  ok "missing desktop id returns failure"
fi
if desktop_file_path "../evil.desktop" >/dev/null 2>&1; then
  no "path-like desktop id should be rejected" "got exit 0"
else
  ok "path-like desktop id rejected"
fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-desktop-file-path: ALL PASS"
  exit 0
fi
echo "test-desktop-file-path: $fails FAILURE(S)"
exit 1
