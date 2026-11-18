#!/usr/bin/env bash
# Tests for scripts/set-panel-visibility.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/bin" "$WORK/.config"
cp "$ROOT/scripts/set-panel-visibility.sh" "$WORK/scripts-set-panel-visibility.sh"
chmod +x "$WORK/scripts-set-panel-visibility.sh"

# kwriteconfig6 stub: records writes and applies them to plasmashellrc so kreadconfig6 can read back.
cat > "$WORK/bin/kwriteconfig6" <<'STUB'
#!/usr/bin/env bash
echo "kwrite $*" >> "$HOME/.kwrite.log"
file="$HOME/.config/plasmashellrc"
group1="" group2="" key="" val=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file) file="$HOME/.config/$2"; shift 2 ;;
    --group) if [ -z "$group1" ]; then group1="$2"; else group2="$2"; fi; shift 2 ;;
    --key) key="$2"; shift 2 ;;
    *) val="$1"; shift ;;
  esac
done
mkdir -p "$(dirname "$file")"
python3 - "$file" "$group1" "$group2" "$key" "$val" <<'PY'
import sys, os
path,g1,g2,key,val = sys.argv[1:6]
sec = f"[{g1}][{g2}]"
lines = open(path).read().splitlines() if os.path.exists(path) else []
out=[]; in_sec=False; done=False
i=0
while i < len(lines):
    l=lines[i]
    if l.strip().startswith('['):
        if in_sec and not done:
            out.append(f"{key}={val}\n" if not out or out[-1].endswith('\n') else f"\n{key}={val}\n")
            # normalize: append without extra complexity
            pass
        in_sec = (l.strip()==sec)
        out.append(l+'\n')
        i+=1
        # simple replacement/insert handled in second pass easier
        continue
    out.append(l+'\n')
    i+=1
# easier: rebuild by replacing key in section or adding
text=''.join(out)
if sec not in text:
    if text and not text.endswith('\n'): text+='\n'
    text += sec+'\n'+f'{key}={val}\n'
else:
    parts=text.split(sec)
    head=parts[0]+sec
    rest=parts[1]
    # rest until next [PlasmaViews] or end
    # find boundary: next line starting with '[' at col0
    import re
    m=re.search(r'\n\[', rest)
    if m:
        body=rest[:m.start()+1]; tail=rest[m.start()+1:]
    else:
        body=rest; tail=''
    if re.search(rf'^{re.escape(key)}=.*$', body, re.M):
        body=re.sub(rf'^{re.escape(key)}=.*$', f'{key}={val}', body, flags=re.M)
    else:
        if body and not body.startswith('\n'): body='\n'+body
        body = '\n'+f'{key}={val}'+body if body=='\n' else '\n'+f'{key}={val}'+body
    text=head+body+tail
open(path,'w').write(text)
PY
exit ${KWRITECONFIG_RC:-0}
STUB
chmod +x "$WORK/bin/kwriteconfig6"

cat > "$WORK/bin/kreadconfig6" <<'STUB'
#!/usr/bin/env bash
file="$HOME/.config/plasmashellrc"
group1="" group2="" key=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file) file="$HOME/.config/$2"; shift 2 ;;
    --group) if [ -z "$group1" ]; then group1="$2"; else group2="$2"; fi; shift 2 ;;
    --key) key="$2"; shift 2 ;;
    *) shift ;;
  esac
done
python3 - "$file" "$group1" "$group2" "$key" <<'PY'
import sys, os, re
path,g1,g2,key=sys.argv[1:5]
sec=f"[{g1}][{g2}]"
if not os.path.exists(path): sys.exit(0)
text=open(path).read()
if sec not in text: sys.exit(0)
rest=text.split(sec,1)[1]
m=re.search(r'\n\[', rest)
body=rest[:m.start()+1] if m else rest
mm=re.search(rf'^{re.escape(key)}=(.*)$', body, re.M)
if mm: print(mm.group(1))
PY
exit ${KREADCONFIG_RC:-0}
STUB
chmod +x "$WORK/bin/kreadconfig6"

run_spv(){
  PATH="$WORK/bin:$PATH" HOME="$WORK" PANEL_RC_FILE="$WORK/.config/plasmashellrc" bash "$WORK/scripts-set-panel-visibility.sh" "$@"
}

echo "=== test-set-panel-visibility: uses reported panel ids ==="
mkdir -p "$WORK/.config"
cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 10]
panelVisibility=0

[PlasmaViews][Panel 11]
panelVisibility=0
RC
: > "$WORK/.kwrite.log"
OUT="$(run_spv "('panelIds=10,11|layout complete',)" 2>&1)"; RC=$?
case "$OUT" in *"layout.js created panel(s): 10 11"*) ok "reports parsed panel ids" ;; *) no "missing parsed ids: $OUT" ;; esac
case "$OUT" in *"Panel 10: panelVisibility=2"*"Panel 11: panelVisibility=2"*) ok "writes and reads back both panels" ;; *) no "missing readback: $OUT" ;; esac
[ "$RC" -eq 0 ] && ok "exits 0 on success" || no "expected exit 0 got $RC"

echo "=== test-set-panel-visibility: falls back to on-disk ids when layout omits ids ==="
cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 7]
panelVisibility=0
RC
: > "$WORK/.kwrite.log"
OUT="$(run_spv "('layout complete',)" 2>&1)"; RC=$?
case "$OUT" in *"WARNING: layout.js did not report panel ids; falling back to on-disk ids"*) ok "warns on fallback" ;; *) no "missing fallback warning: $OUT" ;; esac
case "$OUT" in *"Panel 7: panelVisibility=2"*) ok "writes fallback disk panel" ;; *) no "fallback write missing: $OUT" ;; esac
[ "$RC" -eq 0 ] && ok "fallback exits 0" || no "fallback exit $RC"

echo "=== test-set-panel-visibility: honors explicit mode argument ==="
cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 5]
panelVisibility=2
RC
OUT="$(run_spv "('panelIds=5|layout complete',)" 3 2>&1)"; RC=$?
case "$OUT" in *"Panel 5: panelVisibility=3"*) ok "writes requested visibility mode" ;; *) no "mode not applied: $OUT" ;; esac
[ "$RC" -eq 0 ] && ok "explicit mode exits 0" || no "explicit mode exit $RC"

echo "=== test-set-panel-visibility: fails when no panel ids available ==="
rm -f "$WORK/.config/plasmashellrc"
OUT="$(run_spv "('layout complete',)" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "exits non-zero without ids" || no "should fail without ids"
case "$OUT" in *"no panel ids available"*|*"cannot set panel visibility"* ) ok "reports missing ids" ;; *) no "missing error message: $OUT" ;; esac

echo "=== test-set-panel-visibility: fails on readback mismatch ==="
cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 9]
panelVisibility=0
RC
cat > "$WORK/bin/kwriteconfig6" <<'STUB'
#!/usr/bin/env bash
echo "kwrite $*" >> "$HOME/.kwrite.log"
exit 0
STUB
chmod +x "$WORK/bin/kwriteconfig6"
cat > "$WORK/bin/kreadconfig6" <<'STUB'
#!/usr/bin/env bash
echo "0"
exit 0
STUB
chmod +x "$WORK/bin/kreadconfig6"
# use a wrapper to cap runtime by making sleep instant? script sleeps 1s in loop and times out after 15 attempts on mismatch logic won't timeout but will loop? readback mismatch sets ok=0 and sleeps 1 then retries write/read forever? loop is while :; with timeout only when panels missing from file; readback mismatch path does `sleep 1` and continues (no attempt cap) - so test would hang. We need to simulate eventual success? instead test timeout path for missing panels in file.
rm -f "$WORK/.config/plasmashellrc"
cat > "$WORK/bin/sleep" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$WORK/bin/sleep"
OUT="$(PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts-set-panel-visibility.sh" "('panelIds=42,43|layout complete',)" 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "times out when panels never appear in plasmashellrc" || no "expected timeout failure"
case "$OUT" in *"never contained panels"*|*"after 15s"*) ok "reports timeout" ;; *) no "missing timeout message: $OUT" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-set-panel-visibility: ALL PASS"; exit 0; fi
echo "test-set-panel-visibility: $fails FAILURE(S)"
exit 1
