#!/usr/bin/env bash
# Tests for the plasmashell restart budget and the backup/restore invariant.
#
# (1) apply.sh must stop/start plasmashell EXACTLY once per run. A revision
#     stopped it again as a "Persistence check - reload plasmashell once more"
#     ~20s after the first start, while the fresh shell was still initializing
#     right after scripting-API layout writes; plasmashell then segfaulted
#     during its exit QSettings sync (three coredumps on record). The budget
#     freezes the single-restart flow so that crash class cannot return.
#     Comments mentioning the old flow are fine; CODE lines are not.
# (2) backup.sh's FILES list and restore-backup.sh's AFFECTED list must be the
#     same set. Three files apply.sh writes (baloofilerc,
#     plasma-notifications.conf, powermanagementprofilesrc) were missing from
#     BOTH lists - apply mutated them with no way back. Set equality makes
#     drift fail loudly.
#
# Host-independent: static text checks only.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPLY="$ROOT/apply.sh"
RESTORE="$ROOT/scripts/restore-backup.sh"
BACKUP="$ROOT/backup.sh"
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

for f in "$APPLY" "$RESTORE" "$BACKUP"; do
  [ -f "$f" ] || no "required file exists" "$f missing"
done

# Code lines only: strip full-line comments and their section headers.
code(){ grep -vE '^[[:space:]]*#' "$1"; }

STOPS=$(code "$APPLY" | grep -c 'shutdown_shell')
STARTS=$(code "$APPLY" | grep -c 'start_shell')
[ "$STOPS" -eq 1 ] && ok "apply.sh stops plasmashell exactly once" || no "apply.sh stops plasmashell exactly once" "shutdown_shell calls: $STOPS"
[ "$STARTS" -eq 1 ] && ok "apply.sh starts plasmashell exactly once" || no "apply.sh starts plasmashell exactly once" "start_shell calls: $STARTS"
if [ "$STOPS" -eq "$STARTS" ]; then ok "stop/start counts match"; else no "stop/start counts match" "$STOPS stops vs $STARTS starts"; fi
if code "$APPLY" | grep -q 'reload plasmashell once more'; then no "no second restart step in code" "phrase found"; else ok "no second restart step in code"; fi
SAYCHECK=$(code "$APPLY" | grep -c 'Persistence check')
[ "$SAYCHECK" -eq 0 ] && ok "no persistence-check step remains" || no "no persistence-check step remains" "found in code: $SAYCHECK"

# The single restart must happen BEFORE the layout scripting step, so the shell
# loads the on-disk config fresh and verify.sh observes post-restart state.
if code "$APPLY" | grep -B4 -A4 'shutdown_shell' | grep -qE 'Restarting plasmashell'; then
  ok "restart sits in its own step before layout"
else
  no "restart sits in its own step before layout" "shutdown_shell not adjacent to 'Restarting plasmashell'"
fi

# Restore/backup set equality (sorted token compare).
extract(){
  sed -n "/^$2=/,/^[[:space:]]*)/p" "$1" \
    | tail -n +2 | head -n -1 \
    | tr ' ' '\n' | grep -E '^[A-Za-z0-9._-]+$' | sort
}
RESTORE_SET=$(extract "$RESTORE" 'AFFECTED')
BACKUP_SET=$(extract "$BACKUP" 'FILES')
[ -n "$RESTORE_SET" ] && ok "AFFECTED list parsed non-empty" || no "AFFECTED list parsed non-empty" "restore-backup.sh AFFECTED extraction failed"
[ -n "$BACKUP_SET" ] && ok "FILES list parsed non-empty" || no "FILES list parsed non-empty" "backup.sh FILES extraction failed"
NONEW="$(comm -23 <(printf '%s\n' "$BACKUP_SET") <(printf '%s\n' "$RESTORE_SET"))"
[ -z "$NONEW" ] && ok "restored-set covers every backed-up file" || no "restored-set covers every backed-up file" "missing from AFFECTED: $(echo "$NONEW" | tr '\n' ' ')"
NOTBAK="$(comm -13 <(printf '%s\n' "$BACKUP_SET") <(printf '%s\n' "$RESTORE_SET"))"
[ -z "$NOTBAK" ] && ok "backed-up-set covers every restored file" || no "backed-up-set covers every restored file" "missing from FILES: $(echo "$NOTBAK" | tr '\n' ' ')"

# The three files this project writes that motivated the invariant repair.
for need in baloofilerc plasma-notifications.conf powermanagementprofilesrc; do
  if printf '%s\n' "$RESTORE_SET" | grep -qxF "$need"; then
    ok "AFFECTED includes $need"
  else
    no "AFFECTED includes $need" "absent from restore list"
  fi
done

if [ "$fails" -eq 0 ]; then printf '%s\n' "PASS restart budget & backup invariant"; else printf '%s\n' "FAIL restart budget & backup invariant"; exit 1; fi
