#!/usr/bin/env bash
# Tests for scripts/lib/plasma.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# Create stubs for KDE tools
mkdir -p "$WORK/bin" "$WORK/.config" "$WORK/scripts/lib"

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

cat > "$WORK/bin/kreadconfig6" <<'STUB'
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
groups=(); key=""; i=0
while [ $i -lt ${#args[@]} ]; do
  a="${args[$i]}"
  case "$a" in
    --group) groups+=("${args[$((i+1))]}"); i=$((i+2)) ;;
    --key) key="${args[$((i+1))]}"; i=$((i+2)) ;;
    *) i=$((i+1)) ;;
  esac
done
sec=""; for g in "${groups[@]}"; do sec+="[$g]"; done
[ -f "$file" ] || exit 0
python3 - "$file" "$sec" "$key" <<'PY'
import sys, re
path,sec,key = sys.argv[1:4]
text = open(path).read()
if sec not in text:
    sys.exit(0)
before, rest = text.split(sec,1)
m = re.search(r'\n\[', rest)
body = rest[:m.start()+1] if m else rest
m2 = re.search(rf'^{re.escape(key)}=(.*?)$', body, re.M)
if m2:
    print(m2.group(1))
PY
exit 0
STUB
chmod +x "$WORK/bin/kreadconfig6"

# Source the library with stubs in PATH (export so functions use it at runtime)
export PATH="$WORK/bin:$PATH"
source "$ROOT/scripts/lib/plasma.sh"

# Create fake appletsrc
cat > "$WORK/appletsrc" <<'EOF'
[Containments][100]
plugin=org.kde.panel

[Containments][200]
plugin=org.kde.panel

[Containments][300]
plugin=org.kde.desktopcontainment

[Containments][200][Applets][5]
plugin=org.kde.plasma.icontasks

[Containments][100][Applets][1]
plugin=org.kde.plasma.appmenu
EOF

# Create fake plasmashellrc
cat > "$WORK/plasmashellrc" <<'EOF'
[PlasmaViews][Panel 100]
alignment=132

[PlasmaViews][Panel 100][Defaults]
thickness=44

[PlasmaViews][Panel 200]
alignment=132

[PlasmaViews][Panel 200][Horizontal1920]
minLength=100
maxLength=200

[Updates]
performed=/some/update
EOF

echo "=== test-lib-plasma: get_panel_ids_from_appletsrc ==="
ids=$(get_panel_ids_from_appletsrc "$WORK/appletsrc")
case "$ids" in *"100"*"200"*) ok "returns panel IDs 100 200" ;; *) no "got: $ids" ;; esac

echo "=== test-lib-plasma: detect_dock_panel_id ==="
dock_id=$(detect_dock_panel_id "$WORK/appletsrc")
[ "$dock_id" = "200" ] && ok "detects dock panel 200" || no "got dock_id: $dock_id"

# Test with no dock
cat > "$WORK/appletsrc2" <<'EOF'
[Containments][100]
plugin=org.kde.panel
EOF
detect_dock_panel_id "$WORK/appletsrc2" && no "should fail for no dock" || ok "fails when no dock panel"

echo "=== test-lib-plasma: extract_panel_ids_from_layout ==="
layout_out="panelIds=10,20|top;h=30|bottom;h=50"
ids=$(extract_panel_ids_from_layout "$layout_out")
[ "$ids" = "10,20" ] && ok "extracts panel IDs" || no "got: $ids"

top=$(get_top_panel_id_from_layout "$layout_out")
[ "$top" = "10" ] && ok "gets top panel ID" || no "got: $top"

bottom=$(get_dock_panel_id_from_layout "$layout_out")
[ "$bottom" = "20" ] && ok "gets dock panel ID" || no "got: $bottom"

echo "=== test-lib-plasma: kwrite/kread wrappers ==="
kwrite "$WORK/plasmashellrc" --group PlasmaViews --group "Panel 100" --key testKey "testValue"
val=$(kread "$WORK/plasmashellrc" --group PlasmaViews --group "Panel 100" --key testKey)
[ "$val" = "testValue" ] && ok "kwrite/kread work" || no "got: $val"

# Test read missing key
val=$(kread "$WORK/plasmashellrc" --group PlasmaViews --group "Panel 100" --key missingKey)
[ -z "$val" ] && ok "kread returns empty for missing key" || no "got: $val"

echo "=== test-lib-plasma: panel setting helpers ==="
write_panel_setting "$WORK/plasmashellrc" "100" "newKey" "newValue"
val=$(read_panel_setting "$WORK/plasmashellrc" "100" "newKey")
[ "$val" = "newValue" ] && ok "write_panel_setting/read_panel_setting work" || no "got: $val"

write_panel_defaults "$WORK/plasmashellrc" "100" "defKey" "defValue"
val=$(kread "$WORK/plasmashellrc" --group PlasmaViews --group "Panel 100" --group Defaults --key defKey)
[ "$val" = "defValue" ] && ok "write_panel_defaults works" || no "got: $val"

subgroups=$(get_panel_subgroups "$WORK/plasmashellrc" "200")
case "$subgroups" in *"Horizontal1920"*) ok "get_panel_subgroups finds subgroups" ;; *) no "got: $subgroups" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then echo "test-lib-plasma: ALL PASS"; exit 0; fi
echo "test-lib-plasma: $fails FAILURE(S)"
exit 1