#!/usr/bin/env bash
# Tests for menu.sh main-menu numbering and dispatch.
#
# menu.sh is copied into a temp ROOT and every script the main menu can invoke
# is replaced by a stub that records its name. Choices are fed on stdin, then
# the recorded call is compared with the label the user saw. This catches drift
# between the numbered labels in show_menu and the case arms in the main loop.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

LOG="$WORK/calls.log"
: > "$LOG"

cp "$ROOT/menu.sh" "$WORK/menu.sh"
chmod +x "$WORK/menu.sh"

# Root-level scripts reachable from the main menu. Submenus (choices 1 and
# 7-16) are exercised by their own tests, not copied here.
for s in status.sh doctor.sh verify.sh quick-update.sh backup.sh rollback.sh \
         sync.sh detect.sh install-deps.sh reset.sh; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$s" "$LOG" > "$WORK/$s"
    chmod +x "$WORK/$s"
done
mkdir -p "$WORK/scripts"
for s in toggle-theme.sh preflight-check.sh export-profile.sh import-profile.sh; do
    printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$s" "$LOG" > "$WORK/scripts/$s"
    chmod +x "$WORK/scripts/$s"
done

# Keep the test independent of a live KDE session and of the terminal.
mkdir -p "$WORK/bin"
printf '#!/bin/sh\nexit 1\n' > "$WORK/bin/kreadconfig6"
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/clear"
chmod +x "$WORK/bin/kreadconfig6" "$WORK/bin/clear"

run_menu(){
    : > "$LOG"
    # shellcheck disable=SC2059  # $1 is intentionally a printf escape string
    printf '%b' "$1" | PATH="$WORK/bin:$PATH" HOME="$WORK" TERM=dumb \
        bash "$WORK/menu.sh" > "$WORK/out" 2>&1 || true
}

plain_out(){ sed $'s/\x1b\\[[0-9;]*m//g' "$WORK/out"; }

menu_labels(){ plain_out | sed -n 's/^\([0-9][0-9]*\)) .*/\1/p'; }

assert_label(){
    local n="$1" text="$2" line
    line="$(plain_out | grep -E "^${n}\) " | head -1)"
    case "$line" in
        *"$text"*) ok "label $n is $text" ;;
        *) no "label $n should mention $text" "got: ${line:-<missing>}" ;;
    esac
}

assert_call(){
    local expected="$1" got
    got="$(cat "$LOG")"
    case "$got" in
        "$expected"*) ok "choice runs $expected" ;;
        *) no "choice should run $expected" "got: ${got:-<none>}" ;;
    esac
}

echo "=== test-menu: labels ==="
run_menu '0\n'
labels="$(menu_labels)"
dups="$(printf '%s\n' "$labels" | sort | uniq -d)"
[ -z "$dups" ] && ok "menu numbers are unique" \
    || no "duplicate menu numbers" "$dups"
missing=""
for n in {1..25}; do
    printf '%s\n' "$labels" | grep -qx "$n" || missing="$missing $n"
done
if [ -z "$missing" ]; then
    ok "menu numbers 1-25 are all present"
else
    no "menu numbers missing:$missing" "got: $(printf '%s' "$labels" | tr '\n' ' ')"
fi

assert_label 17 "Quick Update"
assert_label 18 "Create Backup"
assert_label 19 "Rollback to Previous Backup"
assert_label 20 "Sync Current Config to Repo"
assert_label 21 "Detect Environment"
assert_label 22 "Export Current Config as Profile"
assert_label 23 "Import Configuration Profile"
assert_label 24 "Install Dependencies"
assert_label 25 "Reset/Restore Options"

echo "=== test-menu: dispatch ==="
run_menu '17\n\n0\n' ; assert_call "quick-update.sh"
run_menu '18\n\n0\n' ; assert_call "backup.sh"
run_menu '19\n\n0\n' ; assert_call "rollback.sh"
run_menu '20\n\n0\n' ; assert_call "sync.sh"
run_menu '21\n\n0\n' ; assert_call "detect.sh"
run_menu '22\nprofile1\n\n0\n' ; assert_call "export-profile.sh profile1"
run_menu '23\nprofile1\n\n0\n' ; assert_call "import-profile.sh profile1"
run_menu '24\n\n0\n' ; assert_call "install-deps.sh"
run_menu '25\n\n0\n' ; assert_call "reset.sh"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
    echo "test-menu: ALL PASS"
    exit 0
fi
echo "test-menu: $fails FAILURE(S)"
exit 1
