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
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# --- stub apply.sh that records its args ---
STUB="$WORK/apply.sh"
printf '#!/bin/sh\necho "apply called with: $*" >> "%s/calls.log"\n' "$WORK" > "$STUB"
chmod +x "$STUB"

run_toggle(){
  mkdir -p "$WORK/scripts"
  cp "$ROOT/scripts/toggle-theme.sh" "$WORK/scripts/toggle-theme.sh"
  cp "$STUB" "$WORK/apply.sh"
  ( cd "$WORK" && HOME="$WORK" bash "$WORK/scripts/toggle-theme.sh" )
}

reset_calls(){ : > "$WORK/calls.log"; }
last_call(){ tail -1 "$WORK/calls.log" 2>/dev/null || echo "(no call)"; }

set_kdeglobals_lnf(){
  mkdir -p "$WORK/.config"
  printf '[KDE]\nLookAndFeelPackage=%s\n' "$1" > "$WORK/.config/kdeglobals"
}

echo "=== test-toggle-theme: mode selection ==="

# Case 1: kdeglobals LookAndFeelPackage=Orchis-dark -> switch to light
set_kdeglobals_lnf "com.github.vinceliuice.Orchis-dark"
reset_calls
run_toggle
case "$(last_call)" in *"--light"*) ok "Orchis-dark LNF -> applies --light" ;; *) no "Orchis-dark LNF -> expected --light, got: $(last_call)" ;; esac

# Case 2: kdeglobals LookAndFeelPackage=Orchis -> switch to dark
set_kdeglobals_lnf "com.github.vinceliuice.Orchis"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "Orchis LNF -> applies --dark" ;; *) no "Orchis LNF -> expected --dark, got: $(last_call)" ;; esac

# Case 3: kdeglobals missing LookAndFeelPackage key -> default to dark
set_kdeglobals_lnf ""
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "empty LNF -> defaults to --dark" ;; *) no "empty LNF -> expected --dark, got: $(last_call)" ;; esac

# Case 4: kdeglobals file missing entirely -> default to dark
rm -f "$WORK/.config/kdeglobals"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "no kdeglobals -> defaults to --dark" ;; *) no "no kdeglobals -> expected --dark, got: $(last_call)" ;; esac

# Case 5: unknown LNF -> default to dark
set_kdeglobals_lnf "org.kde.breeze"
reset_calls
run_toggle
case "$(last_call)" in *"--dark"*) ok "unknown LNF -> defaults to --dark" ;; *) no "unknown LNF -> expected --dark, got: $(last_call)" ;; esac

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-toggle-theme: ALL PASS"
  exit 0
fi
echo "test-toggle-theme: $fails FAILURE(S)"
exit 1
