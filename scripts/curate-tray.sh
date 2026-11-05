#!/usr/bin/env bash
# spectre-kde -- scripts/curate-tray.sh
# The ONE implementation of "pin the system-tray items, and make sure the live
# tray actually shows them".
#
# Why the clear-then-write toggle: plasmashell only (re)creates the pinned
# plasmoid applets when it observes a CHANGE of the tray's General/extraItems
# key. Writing the same list again is a silent no-op. That is how a tray could
# come back from a plasmashell restart with the pins present in the config file
# but no applets loaded (icons missing) even though tray-config.js "succeeded".
# Clearing the key first guarantees the follow-up write is a genuine change, so
# the applets are recreated every time this runs.
#
# Usage: ./scripts/curate-tray.sh   (requires a running plasmashell)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# shell_on_bus: no pipeline, so `grep -q`'s early exit can never SIGPIPE its
# producer and trip `pipefail` into a false negative (that bug made this check
# fail even though plasmashell owned the bus name). Retries like
# restore-backup.sh's wait_shell_up, because apply restarts plasmashell right
# before this runs.
shell_on_bus() {
    local names
    names="$(busctl --user list 2>/dev/null || true)"
    grep -q '^org\.kde\.plasmashell[[:space:]]' <<< "$names"
}

RETRIES="${CURATE_TRAY_RETRIES:-15}"
ok=0
for _ in $(seq 1 "$RETRIES"); do
    if shell_on_bus; then ok=1; break; fi
    sleep 1
done
if [ "$ok" -ne 1 ]; then
    echo "curate-tray: plasmashell is not running on the session bus" >&2
    exit 1
fi

run_script() { # $1 = JS source
    gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell \
        --method org.kde.PlasmaShell.evaluateScript "$1" 2>&1
}

# Phase 1: clear extraItems so the phase-2 write is always a genuine change.
CLEAR_JS='var ids = panelIds.slice();
var tray = null;
for (var i = 0; i < ids.length; i++) {
    var p = panelById(ids[i]);
    if (!p) continue;
    for (var w = 0; w < p.widgetIds.length; w++) {
        var wid = p.widgetById(p.widgetIds[w]);
        if (wid && wid.type === "org.kde.plasma.systemtray") tray = wid;
    }
}
if (!tray) {
    print("ERROR systemtray not found in any panel");
} else {
    tray.currentConfigGroup = ["General"];
    tray.writeConfig("extraItems", "");
    tray.writeConfig("shownItems", "");
    print("tray cleared");
}'

OUT="$(run_script "$CLEAR_JS")" || true
case "$OUT" in
    *"tray cleared"*) ;;
    *) echo "curate-tray: clear phase failed: $OUT" >&2; exit 1 ;;
esac

# Give plasmashell a beat to process the removal before the re-add.
sleep 1

# Phase 2: write the real pinned list (single source of truth: tray-config.js).
OUT="$(run_script "$(cat "$ROOT/scripts/tray-config.js")")" || true
case "$OUT" in
    *"systemtray curated"*) ;;
    *) echo "curate-tray: pin phase failed: $OUT" >&2; exit 1 ;;
esac

echo "  system tray curated (pinned items recreated)"
