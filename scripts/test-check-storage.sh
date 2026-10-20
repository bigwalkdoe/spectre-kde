#!/usr/bin/env bash
# Tests for check-storage.sh's scrub-status parser.
#
# check-storage.sh runs a real btrfs scrub, so it needs root and a btrfs
# filesystem. Those tests stub the toolchain and run the real script, which
# keeps the parser honest against the output btrfs-progs actually prints.
#
# The regression this exists for: the parser used "btrfs scrub status --raw",
# but that flag only disables human-readable byte units -- it is not a raw
# stats mode. The real output has no JSON and no "device_stats" key, so every
# clean scrub was reported as an unverified storage fault. "btrfs scrub status
# -R" is the flag that prints the per-counter lines.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0
ok(){ printf 'ok   %s\n' "$1"; }
no(){ printf 'FAIL %s\n       %s\n' "$1" "$2"; fails=$((fails + 1)); }

OUT=''; RC=0
run(){ OUT="$(PATH="$BIN:$PATH" bash "$ROOT/scripts/check-storage.sh" "$@" 2>&1)"; RC=$?; }
has(){ case "$OUT" in *"$1"*) ok "$2" ;; *) no "$2" "no line matching: $1
--- got ---
$OUT" ;; esac; }
lacks(){ case "$OUT" in *"$1"*) no "$2" "unexpected line: $1" ;; *) ok "$2" ;; esac; }
rc_is(){ [ "$RC" -eq "$1" ] && ok "$2" || no "$2" "expected exit $1, got $RC
--- got ---
$OUT"; }

# A case is a directory of stubs. id pretends to be root so the script does not
# reach for sudo; findmnt reports one btrfs mount; btrfs serves the fixture
# files; journalctl reports no kernel events.
case_new(){
  CASE="$WORK/$1"; BIN="$CASE/bin"; mkdir -p "$BIN" "$CASE"
  printf '/dev/mapper/test /\n' > "$CASE/mounts"
  : > "$CASE/stats"
  : > "$CASE/journal"
  : > "$CASE/calls"
  cat > "$BIN/id" <<'EOF'
#!/bin/sh
echo 0
EOF
  # The real script asks for TARGET only unless it is deduplicating by UUID.
  # Emulate both shapes so a test can prove which one is used.
  cat > "$BIN/findmnt" <<EOF
#!/bin/sh
cat "$CASE/mounts"
EOF
  cat > "$BIN/btrfs" <<EOF
#!/bin/sh
case "\$*" in
  "scrub start "*) echo "\$*" >> "$CASE/calls"; exit 0 ;;
  "scrub status -R "*) cat "$CASE/status" ;;
  "scrub status -d "*) cat "$CASE/pretty" ;;
  "device stats "*) cat "$CASE/stats" ;;
  *) exit 0 ;;
esac
EOF
  cat > "$BIN/journalctl" <<EOF
#!/bin/sh
cat "$CASE/journal"
EOF
  chmod +x "$BIN/id" "$BIN/findmnt" "$BIN/btrfs" "$BIN/journalctl"
}

# The shape btrfs-progs v7.1 prints for "scrub status -R": a summary header
# followed by tab-indented "key: value" counters. This is deliberately the real
# format (tabs included); a JSON fixture is what let the old parser pass tests
# while failing on a real machine.
scrub_status(){
  cat <<'EOF'
UUID:             16f3ffff-996b-4943-b923-ba2df6891f11
Scrub started:    Tue Oct 20 14:56:53 2026
Status:           finished
Duration:         0:06:49
	data_extents_scrubbed: 123456
	tree_extents_scrubbed: 789
	data_bytes_scrubbed: 987654321
	tree_bytes_scrubbed: 1234567
	read_errors: 0
	csum_errors: 0
	verify_errors: 0
	no_csum: 5
	csum_discards: 0
	super_errors: 0
	malloc_errors: 0
	uncorrectable_errors: 0
	corrected_errors: 0
	unverified_errors: 0
	last_physical: 5555555
EOF
}

pretty_status(){
  cat <<'EOF'
UUID:             16f3ffff-996b-4943-b923-ba2df6891f11
Scrub device /dev/mapper/test (id 1) history
Scrub started:    Tue Oct 20 14:56:53 2026
Status:           finished
EOF
}

zero_stats(){
  cat <<'EOF'
[/dev/mapper/test].write_io_errs    0
[/dev/mapper/test].read_io_errs     0
[/dev/mapper/test].flush_io_errs    0
[/dev/mapper/test].corruption_errs  0
[/dev/mapper/test].generation_errs  0
EOF
}

echo "=== test-check-storage: scrub status parsing ==="

# --- a clean scrub is a clean verdict ---------------------------------------
#
# The positive control. Against the old --raw parser this failed with "could
# not read scrub counters", which is exactly the false alarm that sent the
# user chasing a disk fault after a scrub that had found no errors.
case_new clean
scrub_status > "$CASE/status"
pretty_status > "$CASE/pretty"
zero_stats > "$CASE/stats"
run
rc_is 0 "a clean scrub exits 0"
has "PASS: all" "a clean scrub reports the parsed counters as PASS"
has "scrub counters zero on /" "the PASS names the mount"
has "5 extents have no checksum" "no_csum is reported informationally"
has "No storage fault found." "a clean scrub reaches the clean verdict"
lacks "FAIL" "a clean scrub prints no FAIL line"

# --- a real error counter is still a fault ----------------------------------
#
# The negative control: fixing the format must not turn the script into one
# that always says clean.
case_new broken
scrub_status | sed 's/^\tcsum_errors: 0/\tcsum_errors: 3/; s/^\tread_errors: 0/\tread_errors: 2/' > "$CASE/status"
pretty_status > "$CASE/pretty"
zero_stats > "$CASE/stats"
run
rc_is 1 "a scrub with counter errors exits 1"
has "FAIL: scrub reported errors on /" "a scrub with counter errors names the mount"
has "csum_errors 3" "the failing checksum counter is named"
has "read_errors 2" "the failing read counter is named"
has "A storage fault WAS found" "a scrub with errors reaches the fault verdict"

# --- unparseable status is never a clean verdict ----------------------------
#
# This is the old --raw output: a summary header with byte totals but no
# counters. Absence of counters must report unverified, not PASS.
case_new empty
cat > "$CASE/status" <<'EOF'
UUID:             16f3ffff-996b-4943-b923-ba2df6891f11
Scrub started:    Tue Oct 20 14:56:53 2026
Status:           finished
Duration:         0:06:49
Total to scrub:   210018648064
EOF
pretty_status > "$CASE/pretty"
zero_stats > "$CASE/stats"
run
rc_is 1 "an unparseable scrub status exits 1"
has "FAIL: could not read scrub counters for /" "an unparseable status says it could not read counters"
has "returned something unexpected" "an unparseable status explains why"
lacks "No storage fault found" "an unparseable status is never the clean verdict"

# --- --dry-run stays inconclusive -------------------------------------------
case_new dry
scrub_status > "$CASE/status"
pretty_status > "$CASE/pretty"
zero_stats > "$CASE/stats"
run --dry-run
rc_is 0 "--dry-run exits 0"
has "data itself has not been verified" "--dry-run says the data was not verified"
lacks "No storage fault found" "--dry-run never claims the filesystem is intact"

# --- one scrub per filesystem, not per mount ---------------------------------
#
# / and /home are normally the same btrfs filesystem. Scrubbing each mount
# re-reads and re-checksums the same data twice (about 15 minutes on the test
# machine), so the mount list has to be deduplicated by filesystem UUID.
case_new dedupe
cat > "$CASE/mounts" <<'EOF'
/dev/mapper/test /
/dev/mapper/test /home
EOF
scrub_status > "$CASE/status"
pretty_status > "$CASE/pretty"
zero_stats > "$CASE/stats"
run
rc_is 0 "a filesystem mounted twice still exits 0"
n="$(grep -c '^scrub start ' "$CASE/calls" 2>/dev/null || true)"
[ "$n" -eq 1 ] && ok "a filesystem mounted twice is scrubbed once" \
  || no "a filesystem mounted twice is scrubbed once" "scrub start calls: $n"

echo "--- result ---"
if [ "$fails" -eq 0 ]; then
  echo "test-check-storage: ALL PASS"
  exit 0
fi
echo "test-check-storage: $fails FAILURE(S)"
exit 1
