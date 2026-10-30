#!/usr/bin/env bash
# Tests for scripts/toggle-theme.sh.
#
# Stub apply.sh so we can assert which mode toggle-theme.sh would select
# without actually mutating the live Plasma session.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "$2"; fails=$((fails + 1)); }

# --- stub apply.sh that records its args ---
STUB="$WORK/apply.sh"
printf '#!/bin/sh\necho "apply called with: $*" >> "%s/calls.log"\n' "$WORK" > "$STUB"
chmod +x "$STUB"

run_toggle(){
  mkdir -p "$WORK/scripts"
  cp "$ROOT/scripts/toggle-theme.sh" "$WORK/scripts/toggle-theme.sh"
  # $STUB is already $WORK/apply.sh, so toggle-theme.sh finds it directly.
  ( cd "$WORK" && HOME="$WORK" bash "$WORK/scripts/toggle-theme.sh" )
}

reset_calls(){ : > "$WORK/calls.log"; }
last_call(){ tail -1 "$WORK/calls.log" 2>/dev/null || echo "(no call)"; }

echo "=== test-toggle-theme: mode selection ==="

# Case 1: only .applied-dark exists -> switch to light
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
touch "$WORK/.applied-dark"
reset_calls
run_toggle
case "$(last_call)" in *"--light"*) ok "dark-only marker -> applies --light" ;; *) no "dark-only marker -> expected --light, got: $(last_call)" ;; esac

# Case 2: only .applied-light exists -> switch to dark
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
touch "$WORK/.applied-light"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "light-only marker -> applies --dark" ;; *) no "light-only marker -> expected --dark, got: $(last_call)" ;; esac

# Case 3: both exist, .applied-dark newer -> switch to light
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
touch "$WORK/.applied-light"
sleep 1
touch "$WORK/.applied-dark"
reset_calls
run_toggle
case "$(last_call)" in *"--light"*) ok "both markers, dark newer -> applies --light" ;; *) no "both markers, dark newer -> expected --light, got: $(last_call)" ;; esac

# Case 4: both exist, .applied-light newer -> switch to dark
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
touch "$WORK/.applied-dark"
sleep 1
touch "$WORK/.applied-light"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "both markers, light newer -> applies --dark" ;; *) no "both markers, light newer -> expected --dark, got: $(last_call)" ;; esac

# Case 5: no markers, HOME kdeglobals says Orchis-dark -> switch to light
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
mkdir -p "$WORK/.config"
printf '[KDE]\nLookAndFeelPackage=com.github.vinceliuice.Orchis-dark\n' > "$WORK/.config/kdeglobals"
reset_calls
run_toggle
case "$(last_call)" in *"--light"*) ok "no markers, kdeglobals dark -> applies --light" ;; *) no "no markers, kdeglobals dark -> expected --light, got: $(last_call)" ;; esac

# Case 6: no markers, HOME kdeglobals says Orchis (light) -> switch to dark
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
printf '[KDE]\nLookAndFeelPackage=com.github.vinceliuice.Orchis\n' > "$WORK/.config/kdeglobals"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "no markers, kdeglobals light -> applies --dark" ;; *) no "no markers, kdeglobals light -> expected --dark, got: $(last_call)" ;; esac

# Case 7: no markers, no kdeglobals -> defaults to dark
rm -f "$WORK/.applied-light" "$WORK/.applied-dark"
rm -f "$WORK/.config/kdeglobals"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "no markers, no kdeglobals -> defaults to --dark" ;; *) no "no markers, no kdeglobals -> expected --dark, got: $(last_call)" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-toggle-theme: ALL PASS"
  exit 0
fi
echo "test-toggle-theme: $fails FAILURE(S)"
exit 1
