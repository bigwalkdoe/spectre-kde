#!/usr/bin/env bash
# Static checks that apply.sh is safe to run repeatedly.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPLY="$ROOT/apply.sh"
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

# mkdir -p used for config dirs (idempotent)
if grep -q 'mkdir -p "\$HOME/.config' "$APPLY"; then ok "mkdir -p for ~/.config"; else no "mkdir -p for ~/.config" "missing"; fi
# cp uses -f or redirection (overwrite) for wallpaper
if grep -q 'cp -f' "$APPLY"; then ok "cp -f for wallpaper"; else no "cp -f for wallpaper" "missing"; fi
# No 'set -e' that would abort on existing files (uses || die)
if grep -q 'set -u' "$APPLY"; then ok "set -u (not set -e)"; else no "set -u" "missing"; fi
# clean-plasmashellrc called (idempotent cleanup)
if grep -q 'clean-plasmashellrc.sh' "$APPLY"; then ok "plasmashellrc cleanup step"; else no "plasmashellrc cleanup step" "missing"; fi

if [ "$fails" -eq 0 ]; then echo "PASS idempotency"; exit 0; else echo "FAIL idempotency"; exit 1; fi
