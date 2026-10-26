#!/usr/bin/env bash
# spectre-kde -- scripts/set-panel-visibility.sh
# The ONE implementation of "make both panels dodge windows".
#
# Plasma 6.7's scripting API has no usable visibility property (assignments are
# silently dropped), so fullscreen windows stay BELOW the panels with the default
# view config. The real, Plasma-owned config key is:
#   [PlasmaViews][Panel N] panelVisibility=<n>
# with the enum the shipped Panel View KCM uses (PanelConfiguration.qml):
#   0 = NormalPanel (always visible)   1 = AutoHide
#   2 = DodgeWindows                   3 = WindowsGoBelow
#
# This lives in its own file because it is needed by BOTH apply.sh and
# quick-update.sh, and both run scripts/layout.js - which removes every panel and
# creates new ones with BRAND NEW ids. Writing panelVisibility to the old ids
# after a re-layout silently does nothing (that is how the setting once appeared
# to apply and never took effect); plasmashellrc is also flushed asynchronously,
# so the on-disk ids can lag the live ones. Both callers therefore pass in the
# ids layout.js reported, and this script waits for the file to catch up, writes,
# and reads back.
#
# Usage: set-panel-visibility.sh "<layout.js output>" [mode]
#   <layout.js output>  the string evaluateScript returned (contains panelIds=..)
#   [mode]              panelVisibility value, default $PANEL_VISIBILITY or 2
# Exits non-zero if the value could not be written and read back.
set -u

VIS="${2:-${PANEL_VISIBILITY:-2}}"
PANEL_RC_FILE="$HOME/.config/plasmashellrc"
LAYOUT_OUT="${1:-}"

disk_panel_ids(){ grep -oE '^\[PlasmaViews\]\[Panel [0-9]+\]' "$PANEL_RC_FILE" 2>/dev/null \
                    | grep -oE '[0-9]+' | sort -u | tr '\n' ' ' | sed 's/ $//'; }

WANT_IDS="$(printf '%s' "$LAYOUT_OUT" | grep -oE 'panelIds=[0-9]+,[0-9]+' | head -1 | cut -d= -f2 | tr ',' ' ')"
if [ -n "$WANT_IDS" ]; then
  echo "  layout.js created panel(s): $WANT_IDS"
else
  WANT_IDS="$(disk_panel_ids)"
  echo "  WARNING: layout.js did not report panel ids; falling back to on-disk ids ($WANT_IDS)"
fi
[ -n "$WANT_IDS" ] || { echo "no panel ids available - cannot set panel visibility" >&2; exit 1; }

attempt=0
while :; do
  attempt=$((attempt + 1))
  if [ "$attempt" -gt 15 ]; then
    echo "plasmashellrc never contained panels [$WANT_IDS] after 15s (on disk: $(disk_panel_ids))" >&2
    exit 1
  fi
  HAVE_IDS=" $(disk_panel_ids) "
  all_present=1
  for w in $WANT_IDS; do case "$HAVE_IDS" in *" $w "*) ;; *) all_present=0 ;; esac; done
  if [ "$all_present" -eq 0 ]; then
    sleep 1
    continue
  fi
  for pid in $WANT_IDS; do
    kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $pid" \
      --key panelVisibility "$VIS" || { echo "could not write panelVisibility for panel $pid" >&2; exit 1; }
  done
  # Read back: kwriteconfig6 exiting 0 only means the file was written, not that
  # Plasma kept the key.
  ok=1
  for pid in $WANT_IDS; do
    got="$(kreadconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $pid" \
            --key panelVisibility 2>/dev/null || true)"
    if [ "$got" = "$VIS" ]; then
      echo "  Panel $pid: panelVisibility=$got (dodge windows)"
    else
      echo "  Panel $pid: read back '$got' (expected $VIS) - retrying"
      ok=0
    fi
  done
  [ "$ok" -eq 1 ] && break
  sleep 1
done
