#!/usr/bin/env bash
# Tests for the health checks in verify.sh that count events in a log.
#
# These three read their data through a pipe, so they share one failure mode: a
# verdict derived from a counter cannot tell "nothing happened" from "nothing
# could be read", and both states used to print PASS. Replaying the log is the
# only way to test that, and it needs no Plasma session -- putting stub
# journalctl / fc-cache executables ahead of PATH decides what verify.sh sees.
# That is what lets this run in CI, which cannot run verify.sh itself.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "$2"; fails=$((fails + 1)); }

# A stub set is a directory of fake executables, named so it can go on PATH.
set_new(){ mkdir -p "$WORK/$1"; }
stub(){ printf '#!/bin/sh\n%s\n' "$3" > "$WORK/$1/$2"; chmod +x "$WORK/$1/$2"; }

# Run verify.sh once under a stub set and keep the whole output. Once per set, not
# once per assertion: a run costs ~20s even with the log tools stubbed
# (plasmashell --version, the panel probe, one desktop-file lookup per pinned
# launcher), and a single run is a single coherent state, so every needle is
# asserted against that one capture.
OUT=''
run(){ OUT="$(PATH="$WORK/$1:$PATH" bash "$ROOT/verify.sh" 2>&1)" || true; }
# Only the health lines are asserted on: the rest of verify.sh legitimately fails
# without a live Plasma session, which is why its result line is ignored here.
has(){
  case "$OUT" in
    *"$1"*) ok "$2" ;;
    *) no "$2" "no line matching: $1" ;;
  esac
}
lacks(){
  case "$OUT" in
    *"$1"*) no "$2" "unexpected line: $1" ;;
    *) ok "$2" ;;
  esac
}

echo "=== test-verify: health checks that read a log ==="

# A journal that reads fine and has nothing wrong with it. The crash-line count
# has to be 0 for the PASS branch, and the 24h readability probe has to be
# non-empty, so the stub prints one ordinary line.
set_new quiet
stub quiet journalctl 'echo "systemd: Started Session 12 of user deon."'
stub quiet fc-cache 'exit 0'
run quiet
has "PASS  no plasmashell crash-loop in last 10 min" \
  "readable journal with no crash still reports PASS"
has "PASS  no fs-verity digest mismatch in last 24h" \
  "readable kernel log with no mismatch still reports PASS"
has "PASS  no invalid fontconfig caches" \
  "fc-cache that ran cleanly still reports PASS"

# A journal that reads fine and contains a real crash. This is the positive
# control: without it a test that only ever saw UNVERIFIED would pass while the
# detection it is protecting had silently stopped working.
set_new crash
stub crash journalctl 'echo "plasma-plasmashell.service: Main process exited, code=dumped, status=11/SEGV"'
stub crash fc-cache 'exit 0'
run crash
has "FAIL  no plasmashell crash-loop in last 10 min" \
  "a crash in a readable journal is still detected"
lacks "UNVERIFIED  no plasmashell crash-loop" \
  "a readable journal is never reported as unread"

# A journal that is readable over 24h but has nothing in the last 10 minutes --
# the ordinary state of a session that has not restarted plasmashell recently.
# The verdict has to be PASS, and it can only be if the readability probe asks
# for a wider window than the crash detection does. Probing readability over the
# same 10 minutes would report UNVERIFIED here, i.e. turn the check's blind spot
# into a false alarm on a healthy machine.
set_new quietwindow
stub quietwindow journalctl 'case "$*" in *"24 hours ago"*) echo "systemd: Started Session 12 of user deon." ;; esac'
stub quietwindow fc-cache 'exit 0'
run quietwindow
has "PASS  no plasmashell crash-loop in last 10 min" \
  "a quiet 10-minute window in a readable journal is PASS, not UNVERIFIED"
has "PASS  no fs-verity digest mismatch in last 24h" \
  "a readable kernel log is PASS even when it holds no fs-verity lines"

# The regression this exists for: journalctl prints nothing and exits 0 when it
# cannot open the journal, and fc-cache may not run at all. Every verdict that
# used to come out of these as PASS must now be UNVERIFIED.
set_new dead
stub dead journalctl 'exit 1'
stub dead fc-cache 'echo "fc-cache: cannot open cache" >&2; exit 1'
run dead
has "UNVERIFIED  no plasmashell crash-loop in last 10 min" \
  "an unreadable journal is UNVERIFIED, not PASS"
has "UNVERIFIED  no fs-verity digest mismatch in last 24h" \
  "an unreadable kernel log is UNVERIFIED, not PASS"
has "UNVERIFIED  no invalid fontconfig caches" \
  "an fc-cache that could not run is UNVERIFIED, not PASS"
lacks "PASS  no plasmashell crash-loop" \
  "an unreadable journal never prints PASS"
lacks "PASS  no fs-verity digest mismatch" \
  "an unreadable kernel log never prints PASS"

# --no-health is what apply.sh uses for its non-authoritative pass 1: it must
# drop the whole health block (journal read + forced fontconfig rebuild +
# fs-verity count) rather than silently passing it, so a skipped check can never
# be mistaken for a healthy one. Assert the SKIP marker and the absence of the
# per-check verdicts.
OUT="$(PATH="$WORK/dead:$PATH" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
has "SKIP  health checks (--no-health)" \
  "--no-health reports that health checks were skipped"
lacks "no plasmashell crash-loop" \
  "--no-health does not print a crash-loop verdict"
lacks "no invalid fontconfig caches" \
  "--no-health does not claim the fontconfig caches are clean"
lacks "no fs-verity digest mismatch" \
  "--no-health does not print an fs-verity verdict"

echo "=== test-verify: dock lengthMode and netspeed config checks ==="
set_new cfgok
stub cfgok journalctl 'echo "systemd: Started Session 12 of user deon."'
stub cfgok fc-cache 'exit 0'
# minimal stubs for commands verify.sh may call
for cmd in plasmashell systemctl busctl kscreen-doctor plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-lookandfeel plasma-apply-wallpaperimage kwriteconfig6 uuidgen flock cmp timeout sddm-greeter-qt6; do
  case "$cmd" in
    plasmashell) stub cfgok "$cmd" 'if [ "$1" = "--version" ]; then echo "plasmashell 6.3.4"; fi; exit 0' ;;
    systemctl) stub cfgok "$cmd" 'if [ "$1" = "--user" ] && [ "$2" = "is-active" ]; then echo "active"; fi; exit 0' ;;
    *) stub cfgok "$cmd" 'exit 0' ;;
  esac
done
# kreadconfig6 stub: read simple key from ini-like plasmashellrc or other files
cat > "$WORK/cfgok/kreadconfig6" <<'KRC'
#!/usr/bin/env bash
file="$HOME/.config/plasmashellrc"; g1=""; g2=""; g3=""; key=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --file) file="$HOME/.config/$2"; shift 2 ;;
    --group)
      if [ -z "$g1" ]; then g1="$2"; elif [ -z "$g2" ]; then g2="$2"; else g3="$2"; fi
      shift 2 ;;
    --key) key="$2"; shift 2 ;;
    *) shift ;;
  esac
done
python3 - "$file" "$g1" "$g2" "$g3" "$key" <<'PY'
import sys, os, re
path,g1,g2,g3,key=sys.argv[1:6]
if not os.path.exists(path): sys.exit(0)
# try deepest matching section first
secs=[]
if g3: secs.append(f"[{g1}][{g2}][{g3}]")
if g2: secs.append(f"[{g1}][{g2}]")
secs.append(f"[{g1}]")
text=open(path).read()
for sec in secs:
    if sec in text:
        rest=text.split(sec,1)[1]
        m=re.search(r'\n\[', rest)
        body=rest[:m.start()+1] if m else rest
        mm=re.search(rf'^{re.escape(key)}=(.*)$', body, re.M)
        if mm:
            print(mm.group(1))
            sys.exit(0)
PY
exit 0
KRC
chmod +x "$WORK/cfgok/kreadconfig6"
# gdbus stub returns probe with dock pid 20, fit lenMode, netspeed in top panel
cat > "$WORK/cfgok/gdbus" <<'GDBUS'
#!/usr/bin/env bash
if printf '%s ' "$@" | grep -q 'evaluateScript'; then
  echo "('count=2|panelids=10,20|top;h=30;float=false;align=132;screen=0;lenMode=fill;widgets=org.kde.plasma.appmenu,org.kde.plasma.systemmonitor.net,org.kde.plasma.systemtray,org.kde.plasma.digitalclock;pid=10|bottom;h=52;float=true;align=132;screen=0;lenMode=fit;widgets=org.kde.plasma.kickoff,org.kde.plasma.icontasks,org.kde.plasma.trash;pid=20',)"
  exit 0
fi
exit 0
GDBUS
chmod +x "$WORK/cfgok/gdbus"

# fixture HOME/config
CFGOK_HOME="$WORK/home-cfgok"
mkdir -p "$CFGOK_HOME/.config" "$CFGOK_HOME/.local/share/plasma/look-and-feel"
cat > "$CFGOK_HOME/.config/plasmashellrc" <<'RC'
[PlasmaViews][Panel 10]
alignment=132
panelVisibility=2

[PlasmaViews][Panel 20]
alignment=132
panelVisibility=2

[PlasmaViews][Panel 20][Defaults]
minLength=-1
maxLength=-1
RC
cat > "$CFGOK_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][100]
plugin=org.kde.panel

[Containments][100][Applets][105]
plugin=org.kde.plasma.systemmonitor.net

[Containments][100][Applets][105][Configuration][Sensors]
highPrioritySensorIds=["network/all/download","network/all/upload"]
sensorLabels={"network/all/download":" ","network/all/upload":" "}

[Containments][200]
plugin=org.kde.panel

[Containments][200][Applets][205]
plugin=org.kde.plasma.icontasks

[Containments][200][Applets][205][Configuration][General]
launchers=applications:org.kde.dolphin.desktop
RC
mkdir -p "$WORK/repo-cfgok/scripts"
# minimal root files/dirs referenced by verify paths when run from ROOT? we'll run with real ROOT but HOME overridden
# run verify in fixture context (many other checks may fail, but our target lines should appear)
OUT="$(PATH="$WORK/cfgok:$PATH" HOME="$CFGOK_HOME" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
has "PASS  dock lengthMode = fit (live)" \
  "verify reports PASS for dock lengthMode fit from live probe"
has "PASS  netspeed widget configured (mode=dual labels=false)" \
  "verify reports PASS for compact netspeed config"

# bad netspeed config case
set_new cfgbad
stub cfgbad journalctl 'echo "systemd: Started Session 12 of user deon."'
stub cfgbad fc-cache 'exit 0'
for cmd in plasmashell systemctl busctl kscreen-doctor plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-lookandfeel plasma-apply-wallpaperimage kwriteconfig6 uuidgen flock cmp timeout sddm-greeter-qt6; do
  case "$cmd" in
    plasmashell) stub cfgbad "$cmd" 'if [ "$1" = "--version" ]; then echo "plasmashell 6.3.4"; fi; exit 0' ;;
    systemctl) stub cfgbad "$cmd" 'if [ "$1" = "--user" ] && [ "$2" = "is-active" ]; then echo "active"; fi; exit 0' ;;
    *) stub cfgbad "$cmd" 'exit 0' ;;
  esac
done
cp "$WORK/cfgok/kreadconfig6" "$WORK/cfgbad/kreadconfig6"
cp "$WORK/cfgok/gdbus" "$WORK/cfgbad/gdbus"
CFGBAD_HOME="$WORK/home-cfgbad"
mkdir -p "$CFGBAD_HOME/.config"
cp "$CFGOK_HOME/.config/plasmashellrc" "$CFGBAD_HOME/.config/plasmashellrc"
cat > "$CFGBAD_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'RC'
[Containments][100][Applets][105]
plugin=org.kde.plasma.systemmonitor.net

[Containments][100][Applets][105][Configuration][Sensors]
highPrioritySensorIds=["network/all/download"]
sensorLabels={"network/all/download":"Download"}
RC
OUT="$(PATH="$WORK/cfgbad:$PATH" HOME="$CFGBAD_HOME" bash "$ROOT/verify.sh" --no-health 2>&1)" || true
has "FAIL  netspeed widget config mismatch for mode=dual labels=false" \
  "verify reports FAIL for non-compact netspeed config"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-verify: ALL PASS"
  exit 0
fi
echo "test-verify: $fails FAILURE(S)"
exit 1

