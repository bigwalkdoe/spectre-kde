#!/usr/bin/env bash
# spectre-kde -- scripts/render-kwinrules.sh
# Render config/applied-kwinrulesrc.conf to stdout, substituting the
# @DESKTOP_N@ placeholders with the desktop UUIDs in kwinrc [Desktops] Id_N.
# One shared implementation, used by apply.sh and manage-kwin-rules.sh, so the
# two can never drift.
#
# kwinrc Id_N values are managed by apply.sh (it preserves existing ids and
# generates missing ones), so by the time this runs those keys exist.
#
# Usage: ./scripts/render-kwinrules.sh > ~/.config/kwinrulesrc

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/config/applied-kwinrulesrc.conf"

content="$(cat "$SRC")"
for n in 1 2 3 4; do
    id="$(kreadconfig6 --file kwinrc --group Desktops --key "Id_$n" 2>/dev/null || true)"
    if [ -n "$id" ]; then
        content="${content//@DESKTOP_${n}@/$id}"
    fi
done

# An unresolved placeholder means the target desktop id is missing; write
# nothing rather than a half-rendered file, so the caller can fail loudly.
if printf '%s' "$content" | grep -q '@DESKTOP_[0-9][0-9]*@'; then
    echo "render-kwinrules: unresolved desktop placeholder (kwinrc [Desktops] Id_N missing?)" >&2
    exit 1
fi

printf '%s\n' "$content"
