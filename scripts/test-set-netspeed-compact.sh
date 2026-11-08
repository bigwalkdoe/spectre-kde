#!/usr/bin/env bash
# Tests for scripts/set-netspeed-compact.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/scripts" "$WORK/bin" "$WORK/.config"

cat > "$WORK/bin/kwriteconfig6" <<'STUB'
#!/usr/bin/env bash
echo "kwrite $*" >> "$HOME/.kwrite.log"
exit 0
STUB
chmod +x "$WORK/bin/kwriteconfig6"

cp "$ROOT/scripts/set-netspeed-compact.sh" "$WORK/scripts/set-netspeed-compact.sh"
chmod +x "$WORK/scripts/set-netspeed-compact.sh"

# Minimal appletsrc with top panel 100 containing systemmonitor.net applet 105
cat > "$WORK/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][100]
plugin=org.kde.panel

[Containments][100][Applets][105]
plugin=org.kde.plasma.systemmonitor.net

[Containments][100][Applets][105][Configuration][Appearance]
chartFace=org.kde.ksysguard.linechart
title=Network Speed

[Containments][100][Applets][105][Configuration][Sensors]
highPrioritySensorIds=["network/all/download","network/all/upload"]

[Containments][200]
plugin=org.kde.panel
RC

run(){ PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts/set-netspeed-compact.sh" "$@"; }

echo "=== test-set-netspeed-compact: applies to top panel ==="
: > "$WORK/.kwrite.log"
OUT="$(run "('panelIds=100,200|layout complete',)" 2>&1)"
case "$OUT" in *"applied to top panel 100 applet 105"*) ok "found and applied" ;; *) no "out: $OUT" ;; esac
if grep -q 'chartFace.*textonly' "$WORK/.kwrite.log"; then ok "sets textonly"; else no "no textonly write: $(cat "$WORK/.kwrite.log")"; fi
if grep -Fq -- '--delete' "$WORK/.kwrite.log"; then ok "deletes title"; else no "no delete: $(cat "$WORK/.kwrite.log")"; fi

echo "=== test-set-netspeed-compact: skips when no panel id ==="
: > "$WORK/.kwrite.log"
OUT="$(run "('no ids',)" 2>&1)"
case "$OUT" in *"skipping"*) ok "skips without panel id" ;; *) no "out: $OUT" ;; esac
[ ! -s "$WORK/.kwrite.log" ] && ok "no writes when skipped" || no "unexpected writes"

echo "=== test-set-netspeed-compact: skips when disabled ==="
mkdir -p "$WORK/scripts"
cat > "$WORK/scripts/topbar-config" <<'CFG'
TOPBAR_SHOW_NETSPEED=false
CFG
: > "$WORK/.kwrite.log"
OUT="$(run "('panelIds=100,200|layout complete',)" 2>&1)"
case "$OUT" in *"disabled"*) ok "skips when disabled" ;; *) no "out: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-set-netspeed-compact: ALL PASS"; exit 0; fi
echo "test-set-netspeed-compact: $fails FAILURE(S)"
exit 1
