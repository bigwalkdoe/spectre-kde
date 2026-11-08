#!/usr/bin/env bash
# Tests for scripts/manage-shortcuts.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/bin" "$WORK/.config"

# Stub kreadconfig6: reads from $WORK/.config/kglobalshortcutsrc in simple key= form fallback
cat > "$WORK/bin/kreadconfig6" <<'STUB'
#!/usr/bin/env bash
# --file kglobalshortcutsrc --group G --key K
file="" group="" key=""
while [ $# -gt 0 ]; do
  case "$1" in
    --file) file="$2"; shift 2 ;;
    --group) group="$2"; shift 2 ;;
    --key) key="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[ "$file" = "kglobalshortcutsrc" ] && file="$HOME/.config/kglobalshortcutsrc"
[ -f "$file" ] || exit 0
awk -v g="[$group]" -v k="$key" '
  $0==g {inside=1; next}
  /^\[/ {inside=0}
  inside && index($0,k"=")==1 {print substr($0,length(k)+2); found=1; exit}
  END{exit(found?0:1)}
' "$file"
STUB
cat > "$WORK/bin/kwriteconfig6" <<'STUB'
#!/usr/bin/env bash
echo "kwrite $*" >> "$HOME/.kwrite.log"
exit 0
STUB
chmod +x "$WORK/bin/kreadconfig6" "$WORK/bin/kwriteconfig6"

cp "$ROOT/scripts/manage-shortcuts.sh" "$WORK/scripts/manage-shortcuts.sh"
cp "$ROOT/scripts/shortcuts-declared.conf" "$WORK/scripts/shortcuts-declared.conf"
chmod +x "$WORK/scripts/manage-shortcuts.sh"

# Live config matching declared defaults for tested entries
cat > "$WORK/.config/kglobalshortcutsrc" <<RC
[kwin]
Overview=Meta+W,Meta+W,Toggle Overview
Grid View=Meta+G,Meta+G,Toggle Grid View
Show Desktop=Meta+D,Meta+D,Peek at Desktop
Edit Tiles=Meta+T,Meta+T,Toggle Tiles Editor
Switch One Desktop to the Left=Meta+Ctrl+Left,Meta+Ctrl+Left,Switch One Desktop to the Left
Switch One Desktop to the Right=Meta+Ctrl+Right,Meta+Ctrl+Right,Switch One Desktop to the Right
Window One Desktop to the Left=Meta+Ctrl+Shift+Left,Meta+Ctrl+Shift+Left,Window One Desktop to the Left
Window One Desktop to the Right=Meta+Ctrl+Shift+Right,Meta+Ctrl+Shift+Right,Window One Desktop to the Right
Walk Through Windows=Alt+Tab	Meta+Tab,Alt+Tab,Walk Through Windows
Walk Through Windows (Reverse)=Alt+Shift+Tab	Meta+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)

[plasmashell]
activate application launcher=Meta	Alt+F1,Alt+F1,Activate Application Launcher
RC

run(){ PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts/manage-shortcuts.sh" "$@"; }

echo "=== test-manage-shortcuts: list ==="
OUT="$(run list)"
case "$OUT" in *"Overview"*Meta+W*) ok "list shows overview" ;; *) no "list: $OUT" ;; esac

echo "=== test-manage-shortcuts: status ok ==="
OUT="$(run status 2>&1)" || true
case "$OUT" in *"drift=0 missing=0"*) ok "status all ok" ;; *) no "status: $OUT" ;; esac

echo "=== test-manage-shortcuts: status drift ==="
sed -i 's/^Grid View=.*/Grid View=Meta+H,Meta+G,Toggle Grid View/' "$WORK/.config/kglobalshortcutsrc"
OUT="$(run status 2>&1)" || true
case "$OUT" in *"DRIFT"*Grid\ View*) ok "status detects drift" ;; *) no "drift: $OUT" ;; esac
sed -i 's/^Grid View=.*/Grid View=Meta+G,Meta+G,Toggle Grid View/' "$WORK/.config/kglobalshortcutsrc"

echo "=== test-manage-shortcuts: apply refuses without --yes ==="
OUT="$(run apply 2>&1)" && no "apply should refuse" || ok "apply refused without --yes"
case "$OUT" in *"--yes"*) ok "apply mentions --yes" ;; *) no "apply msg: $OUT" ;; esac

echo "=== test-manage-shortcuts: apply --yes ==="
: > "$WORK/.kwrite.log"
OUT="$(run apply --yes 2>&1)"
case "$OUT" in *"Applied 11 shortcut"*) ok "apply reports count" ;; *) no "apply: $OUT" ;; esac
if grep -q 'kwin.*Overview' "$WORK/.kwrite.log"; then ok "kwrite logged"; else no "no kwrite log"; fi

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-manage-shortcuts: ALL PASS"; exit 0; fi
echo "test-manage-shortcuts: $fails FAILURE(S)"
exit 1
