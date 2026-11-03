#!/usr/bin/env bash
# Tests for scripts/manage-splash.sh (list/current only; set requires live session).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

# Stub external KDE tools so the suite runs without a live Plasma session
STUBS="$WORK/bin"
mkdir -p "$STUBS"
cat > "$STUBS/kwriteconfig6" <<'STUB'
#!/bin/sh
exit 0
STUB
cat > "$STUBS/kreadconfig6" <<'STUB'
#!/bin/sh
echo "(unset)"
STUB
chmod +x "$STUBS/kwriteconfig6" "$STUBS/kreadconfig6"
export PATH="$STUBS:$PATH"
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts"
cp "$ROOT/scripts/manage-splash.sh" "$WORK/scripts/manage-splash.sh"
cp "$ROOT/scripts/splash-theme-path.sh" "$WORK/scripts/splash-theme-path.sh"
chmod +x "$WORK/scripts/manage-splash.sh" "$WORK/scripts/splash-theme-path.sh"

# Provide a fake look-and-feel splash tree
mkdir -p "$WORK/.local/share/plasma/look-and-feel/AppleSplash/contents/splash"
echo "qml" > "$WORK/.local/share/plasma/look-and-feel/AppleSplash/contents/splash/Splash.qml"

run(){ HOME="$WORK" XDG_DATA_HOME="$WORK/.local/share" bash "$WORK/scripts/manage-splash.sh" "$@"; }

echo "=== test-manage-splash: list ==="
OUT="$(run list)"
case "$OUT" in *"AppleSplash"*) ok "list shows AppleSplash" ;; *) no "list missing AppleSplash: $OUT" ;; esac

echo "=== test-manage-splash: current ==="
OUT="$(run current)"
case "$OUT" in *"Current splash:"*) ok "current works" ;; *) no "current failed: $OUT" ;; esac

echo "=== test-manage-splash: set valid ==="
OUT="$(run set AppleSplash)"
case "$OUT" in *"Splash set to: AppleSplash"*) ok "set valid works" ;; *) no "set failed: $OUT" ;; esac

echo "=== test-manage-splash: set invalid ==="
OUT="$(run set NonexistentTheme 2>&1)" || true
case "$OUT" in *"not found"*) ok "set invalid rejected" ;; *) no "set invalid not rejected: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-splash: ALL PASS"; exit 0; fi
echo "test-manage-splash: $fails FAILURE(S)"
exit 1