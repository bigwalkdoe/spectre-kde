#!/usr/bin/env bash
# Tests for scripts/manage-notifications.sh.
#
# Stubs qdbus6 and uses a temporary NOTIF_CONF so no real config is mutated.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# --- stub qdbus6 ---
mkdir -p "$WORK/bin"
printf '#!/bin/sh\n# stub qdbus6 - report DND state from env var\n# qdbus6 ... Properties.Get <interface> DoNotDisturb -> $5\n# qdbus6 ... Properties.Set <interface> DoNotDisturb <val> -> $5, $6\nif [ "$5" = "DoNotDisturb" ]; then\n  case \"$3\" in\n    *Get) echo \"${DND_STATE:-false}\" ;;\n    *Set) DND_STATE=\"$6\"; exit 0 ;;\n  esac\nelse\n  exit 0\nfi\n' > "$WORK/bin/qdbus6"
chmod +x "$WORK/bin/qdbus6"

# --- applied config (reset source) ---
mkdir -p "$ROOT/config" 2>/dev/null || true
APPLIED="$ROOT/config/applied-plasma-notifications.conf"
if [ ! -f "$APPLIED" ]; then
  mkdir -p "$(dirname "$APPLIED")"
  cat > "$APPLIED" <<'EOF'
[Notifications]
DoNotDisturb=false
[Applications][org.mozilla.firefox.desktop]
Enabled=true
EOF
fi

NOTIF_CONF="$WORK/.config/plasma-notifications.conf"
mkdir -p "$(dirname "$NOTIF_CONF")"

run_notif(){
  PATH="$WORK/bin:$PATH" HOME="$WORK" DND_STATE="${DND_STATE:-false}" \
    bash "$ROOT/scripts/manage-notifications.sh" "$@"
}

echo "=== test-manage-notifications: status ==="
OUT="$(run_notif status)"
case "$OUT" in
  *"Notification Status"* ) ok "status prints header" ;;
  *) no "status missing header: $OUT" ;;
esac
case "$OUT" in
  *"Do Not Disturb: false"* ) ok "status shows DND=false" ;;
  *) no "status missing DND=false: $OUT" ;;
esac

echo "=== test-manage-notifications: enable-dnd ==="
DND_STATE="false" OUT="$(run_notif enable-dnd)"
case "$OUT" in
  *"Do Not Disturb enabled"* ) ok "enable-dnd reports success" ;;
  *) no "enable-dnd missing success: $OUT" ;;
esac

echo "=== test-manage-notifications: disable-dnd ==="
DND_STATE="true" OUT="$(run_notif disable-dnd)"
case "$OUT" in
  *"Do Not Disturb disabled"* ) ok "disable-dnd reports success" ;;
  *) no "disable-dnd missing success: $OUT" ;;
esac

echo "=== test-manage-notifications: list-apps ==="
echo '[Applications][org.mozilla.firefox.desktop]' > "$NOTIF_CONF"
echo 'Enabled=true' >> "$NOTIF_CONF"
OUT="$(run_notif list-apps)"
case "$OUT" in
  *"org.mozilla.firefox.desktop"* ) ok "list-apps shows firefox app" ;;
  *) no "list-apps missing firefox: $OUT" ;;
esac

echo "=== test-manage-notifications: list-apps empty ==="
echo '' > "$NOTIF_CONF"
OUT="$(run_notif list-apps)"
case "$OUT" in
  *"No per-app settings"* ) ok "list-apps empty reports none" ;;
  *) no "list-apps empty should report none: $OUT" ;;
esac

echo "=== test-manage-notifications: reset ==="
echo 'DoNotDisturb=true' > "$NOTIF_CONF"
cp "$APPLIED" "$NOTIF_CONF" 2>/dev/null || true
OUT="$(run_notif reset)"
case "$OUT" in
  *"Defaults restored"* ) ok "reset reports success" ;;
  *) no "reset missing success: $OUT" ;;
esac

echo "=== test-manage-notifications: default is status ==="
OUT="$(run_notif)"
case "$OUT" in
  *"Notification Status"* ) ok "no-args runs status (default)" ;;
  *) no "no-args should default to status: $OUT" ;;
esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-manage-notifications: ALL PASS"
  exit 0
fi
echo "test-manage-notifications: $fails FAILURE(S)"
exit 1
