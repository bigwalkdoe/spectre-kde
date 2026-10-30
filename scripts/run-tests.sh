#!/usr/bin/env bash
# spectre-kde -- scripts/run-tests.sh
# Run every scripts/test-*.sh suite and print a summary.
#
# The suites stub external KDE tools and use temp dirs, so no live Plasma
# session is required. CI calls this same entry point, which means adding a
# new scripts/test-*.sh file automatically runs it on every push.
#
# Usage: ./scripts/run-tests.sh [suite ...]
#        ./scripts/run-tests.sh test-menu.sh test-manage-dock.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
shopt -s nullglob

if [ "$#" -gt 0 ]; then
    tests=()
    for name in "$@"; do
        case "$name" in
            */*) candidate="$name" ;;
            *)   candidate="$ROOT/scripts/$name" ;;
        esac
        if [ ! -f "$candidate" ]; then
            echo "run-tests: no such test suite: $name" >&2
            exit 2
        fi
        tests+=("$candidate")
    done
else
    tests=("$ROOT"/scripts/test-*.sh)
fi

if [ "${#tests[@]}" -eq 0 ]; then
    echo "run-tests: no test suites found under $ROOT/scripts" >&2
    exit 1
fi

passed=0
failed=0
failed_names=()

for t in "${tests[@]}"; do
    name="$(basename "$t")"
    echo "================================================================"
    echo "=== $name"
    echo "================================================================"
    if timeout 300 bash "$t"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        failed_names+=("$name")
    fi
    echo ""
done

echo "================================================================"
echo "=== test summary"
echo "================================================================"
echo "  passed: $passed"
echo "  failed: $failed"
if [ "$failed" -ne 0 ]; then
    printf '  failed suites: %s\n' "${failed_names[*]}"
    exit 1
fi
echo "run-tests: ALL PASS"
