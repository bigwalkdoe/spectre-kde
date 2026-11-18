#!/usr/bin/env bash
# Tests for scripts/set-dock-view-settings.sh.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

mkdir -p "$WORK/bin" "$WORK/.config" "$WORK/scripts"
cp "$ROOT/scripts/set-dock-view-settings.sh" "$WORK/scripts/set-dock-view-settings.sh"
chmod +x "$WORK/scripts/set-dock-view-settings.sh"

cat > "$WORK/bin/kwriteconfig6" <<'STUB'
#!/usr/bin/env bash
file="$HOME/.config/plasmashellrc"; args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file)
      case "$2" in /*) file="$2" ;; *) file="$HOME/.config/$2" ;; esac
      shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
# args: --group ... --key k [--delete|value]
groups=(); key=""; val=""; del=0
i=0
while [ $i -lt ${#args[@]} ]; do
  a="${args[$i]}"
  case "$a" in
    --group) groups+=("${args[$((i+1))]}"); i=$((i+2)) ;;
    --key) key="${args[$((i+1))]}"; i=$((i+2)) ;;
    --delete) del=1; i=$((i+1)) ;;
    *) val="$a"; i=$((i+1)) ;;
  esac
done
sec=""; for g in "${groups[@]}"; do sec+="[$g]"; done
mkdir -p "$(dirname "$file")"
python3 - "$file" "$sec" "$key" "$val" "$del" <<'PY'
import sys, os, re
path,sec,key,val,dele = sys.argv[1:6]
dele = (dele == '1')
text = open(path).read() if os.path.exists(path) else ''
if sec not in text:
    if dele:
        open(path,'w').write(text); sys.exit(0)
    if text and not text.endswith('\n'): text += '\n'
    text += sec + '\n' + f'{key}={val}\n'
    open(path,'w').write(text); sys.exit(0)
before, rest = text.split(sec,1)
m = re.search(r'\n\[', rest)
body = rest[:m.start()+1] if m else rest
tail = rest[m.start()+1:] if m else ''
if dele:
    body = re.sub(rf'^{re.escape(key)}=.*\n?', '', body, flags=re.M)
else:
    if re.search(rf'^{re.escape(key)}=.*$', body, re.M):
        body = re.sub(rf'^{re.escape(key)}=.*$', f'{key}={val}', body, flags=re.M)
    else:
        if body == '' or body.startswith('\n'):
            ins = f'\n{key}={val}\n'
            body = ins + (body[1:] if body.startswith('\n') else body)
        else:
            body = f'\n{key}={val}\n' + body
open(path,'w').write(before + sec + body + tail)
PY
exit 0
STUB
chmod +x "$WORK/bin/kwriteconfig6"

cat > "$WORK/bin/gdbus" <<'STUB'
#!/usr/bin/env bash
echo "gdbus $*" >> "$HOME/.gdbus.log"
exit 0
STUB
chmod +x "$WORK/bin/gdbus"

cat > "$WORK/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 20]
panelVisibility=2

[PlasmaViews][Panel 20][Defaults]
thickness=44

[PlasmaViews][Panel 20][Horizontal1920]
thickness=44
minLength=0
maxLength=100

[PlasmaViews][Panel 20][Horizontal2560]
thickness=44
minLength=10
maxLength=200

[PlasmaViews][Panel 10]
alignment=132
RC

run_set(){
  PATH="$WORK/bin:$PATH" HOME="$WORK" bash "$WORK/scripts/set-dock-view-settings.sh" "$@"
}

echo "=== test-set-dock-view-settings: fit centered floating ==="
: > "$WORK/.gdbus.log"
OUT="$(run_set 20 true true true 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0" || no "exit $RC: $OUT"
grep -q '^\[PlasmaViews\]\[Panel 20\]$' "$WORK/.config/plasmashellrc" && ok "keeps panel section" || no "lost panel section"
# base alignment/floating
awk '
  /^\[PlasmaViews\]\[Panel 20\]$/ {inb=1; next}
  /^\[/ {inb=0}
  inb && /^alignment=132$/ {a=1}
  inb && /^floating=1$/ {f=1}
  END{exit !(a&&f)}
' "$WORK/.config/plasmashellrc" && ok "sets base alignment and floating" || no "base keys missing/wrong"
# Defaults fit
awk '
  /^\[PlasmaViews\]\[Panel 20\]\[Defaults\]$/ {inb=1; next}
  /^\[/ {inb=0}
  inb && /^minLength=-1$/ {mi=1}
  inb && /^maxLength=-1$/ {ma=1}
  END{exit !(mi&&ma)}
' "$WORK/.config/plasmashellrc" && ok "sets Defaults min/max to fit" || no "Defaults fit keys missing"
# screen-specific groups updated
awk '
  /^\[PlasmaViews\]\[Panel 20\]\[Horizontal1920\]$/ {inb=1; next}
  /^\[/ {inb=0}
  inb && /^minLength=-1$/ {mi=1}
  inb && /^maxLength=-1$/ {ma=1}
  END{exit !(mi&&ma)}
' "$WORK/.config/plasmashellrc" && ok "updates Horizontal1920 subgroup to fit" || no "Horizontal1920 not updated"
awk '
  /^\[PlasmaViews\]\[Panel 20\]\[Horizontal2560\]$/ {inb=1; next}
  /^\[/ {inb=0}
  inb && /^minLength=-1$/ {mi=1}
  inb && /^maxLength=-1$/ {ma=1}
  END{exit !(mi&&ma)}
' "$WORK/.config/plasmashellrc" && ok "updates Horizontal2560 subgroup to fit" || no "Horizontal2560 not updated"
grep -q "lengthMode='fit'" "$WORK/.gdbus.log" && ok "sets live lengthMode to fit" || no "missing live fit call"

echo "=== test-set-dock-view-settings: fill left non-floating ==="
: > "$WORK/.gdbus.log"
OUT="$(run_set 20 false false false 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "exits 0 for fill mode" || no "exit $RC: $OUT"
awk '
  /^\[PlasmaViews\]\[Panel 20\]$/ {inb=1; next}
  /^\[/ {inb=0}
  inb && /^alignment=1$/ {a=1}
  END{exit !a}
' "$WORK/.config/plasmashellrc" && ok "sets left alignment" || no "left alignment missing"
grep -q "lengthMode='fill'" "$WORK/.gdbus.log" && ok "sets live lengthMode to fill" || no "missing live fill call"

echo "=== test-set-dock-view-settings: requires panel id ==="
OUT="$(run_set '' true true true 2>&1)"; RC=$?
[ "$RC" -ne 0 ] && ok "fails without panel id" || no "should fail without panel id"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-set-dock-view-settings: ALL PASS"; exit 0; fi
echo "test-set-dock-view-settings: $fails FAILURE(S)"
exit 1
