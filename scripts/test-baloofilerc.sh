#!/usr/bin/env bash
# Tests for config/applied-baloofilerc.conf.
#
# Baloo 6.31 reads EXACTLY these keys (src/lib/baloosettings.kcfg):
#   folders[$e], exclude folders[$e], "exclude filters"/version.
# The space-less camelCase spellings are keys Baloo never reads: apply once
# wrote `excludeFolders=`/`excludeFilters=` and the indexer could gain no
# include list at all, spinning "Failed to add include folder config entry"
# against the file forever. These tests freeze the canonical shape so the
# template cannot drift back into a key the engine ignores.
#
# Host-independent: pure grep/awk checks plus a sed expansion smoke test; no
# balooctl, no live Plasma session.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$ROOT/config/applied-baloofilerc.conf"
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "${2:-}"; fails=$((fails + 1)); }

[ -f "$TPL" ] || { no "template exists" "$TPL missing"; printf '%s\n' "FAIL baloofilerc template"; exit 1; }

# 1. Canonical list keys present, no space-less legacy spellings.
if grep -qE '^folders\[.e\]=' "$TPL"; then ok "folders[\$e] present"; else no "folders[\$e] present" "canonical include list key missing"; fi
if grep -qE '^exclude folders\[.e\]=' "$TPL"; then ok "exclude folders[\$e] present"; else no "exclude folders[\$e] present" "canonical exclude key missing"; fi
JUNK=$(grep -nE '^(excludeFolders|excludeFilters|excludeMimetypes|onlyIndexLocalFiles|useInotify|indexHidden|maxFileSize|idleTimeout|basicIndexingOnly)=' "$TPL")
[ -z "$JUNK" ] && ok "no camelCase junk keys" || no "no camelCase junk keys" "$JUNK"

# 2. No invalid KConfig escapes (a single backslash-# killed the old file).
ESC=$(grep -nF '\#' "$TPL")
[ -z "$ESC" ] && ok "no invalid escapes" || no "no invalid escapes" "$ESC"
BS=$(grep -nEn '\\\\' "$TPL")
[ -z "$BS" ] && ok "no stray backslashes" || no "no stray backslashes" "$BS"

# Helper: value of a named canonical key line in the given FILE.
keyval(){ grep -E "^$1\[.e\]=" "$2" | head -1; }

# 3. Exclude list: comma entries, each with a trailing slash as @HOME@ or
#    $HOME alias form.
EXC_VAL="$(keyval 'exclude folders' "$TPL")"
EXC_VAL="${EXC_VAL#*=}"
[ -n "$EXC_VAL" ] && ok "exclude list non-empty" || no "exclude list non-empty" "exclude entry has no value"
BAD=$(printf '%s' "$EXC_VAL" | tr ',' '\n' | grep -vE '^(\$HOME|@HOME@)/.*/$' | head -3)
[ -z "$BAD" ] && ok "all exclude entries have trailing slash" || no "all exclude entries have trailing slash" "$BAD"

# 4. Include list form: home root only.
INC_VAL="$(keyval 'folders' "$TPL")"
case "${INC_VAL#*=}" in
  '@HOME@/'|'$HOME/')        ok "include list is the home root" ;;
  '')                        no "include list is the home root" "folders[\$e] key has no value" ;;
  *)                         no "include list is the home root" "${INC_VAL#*=}" ;;
esac

# 5. Expansion smoke test: every @HOME@ resolves and none remain; the expanded
#    file carries only canonical keys with absolute, trailing-slash entries.
EXP="$(mktemp)"
trap 'rm -f "$EXP"' EXIT
sed "s|@HOME@|$HOME|g" "$TPL" > "$EXP" || no "sed expansion ran" "sed failed"
if grep -q '@HOME@' "$EXP"; then no "expansion removed all placeholders" "$(grep -n '@HOME@' "$EXP" | head -3)"; else ok "expansion removed all placeholders"; fi
EXP_EXC="$(keyval 'exclude folders' "$EXP")"
EXP_EXC="${EXP_EXC#*=}"
EXP_BAD=$(printf '%s' "$EXP_EXC" | tr ',' '\n' | grep -vE '^/[^,]*/$' | head -3)
[ -z "$EXP_BAD" ] && ok "expanded entries absolute with trailing slash" || no "expanded entries absolute with trailing slash" "$EXP_BAD"
EXP_JUNK=$(grep -nE '^(excludeFolders|excludeFilters)=' "$EXP")
[ -z "$EXP_JUNK" ] && ok "expanded file has no junk keys" || no "expanded file has no junk keys" "$EXP_JUNK"
TMP_BUILT="$(printf '%s' "$EXP_EXC" | tr ',' '\n' | grep -c "^$HOME/.cache/$")"
[ "$TMP_BUILT" -ge 1 ] && ok "expansion resolves @HOME@ to the real home" || no "expansion resolves @HOME@ to the real home" "expanded cache entry missing"

# 6. Documentation matches reality: the header must warn about the camelCase
#    trap (that is what this file once shipped).
if grep -qE 'keys Baloo never reads|Baloo never reads' "$TPL"; then
  ok "header documents the camelCase failure mode"
else
  no "header documents the camelCase failure mode" "the contract comment is missing"
fi

if [ "$fails" -eq 0 ]; then printf '%s\n' "PASS baloofilerc template"; else printf '%s\n' "FAIL baloofilerc template"; exit 1; fi
