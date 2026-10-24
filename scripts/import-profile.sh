#!/usr/bin/env bash
# spectre-kde -- import-profile.sh
# Import configuration from a profile

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE_NAME="${1:-}"
PROFILE_DIR="$ROOT/profiles/$PROFILE_NAME"

if [ -z "$PROFILE_NAME" ]; then
    echo "Usage: $0 <profile-name>"
    echo ""
    echo "Available profiles:"
    ls -1 "$ROOT/profiles/" 2>/dev/null || echo "  (none)"
    exit 1
fi

if [ ! -d "$PROFILE_DIR" ]; then
    echo "Error: Profile not found: $PROFILE_DIR"
    echo ""
    echo "Available profiles:"
    ls -1 "$ROOT/profiles/" 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "Importing profile: $PROFILE_NAME"
echo ""

# Import dock configuration
[ -f "$PROFILE_DIR/dock-launchers.list" ] && cp "$PROFILE_DIR/dock-launchers.list" "$ROOT/scripts/" && echo "✓ Imported dock launchers"
[ -f "$PROFILE_DIR/dock-config" ] && cp "$PROFILE_DIR/dock-config" "$ROOT/scripts/" && echo "✓ Imported dock config"

# Import autostart
[ -f "$PROFILE_DIR/autostart.list" ] && cp "$PROFILE_DIR/autostart.list" "$ROOT/scripts/" && echo "✓ Imported autostart list"

# Show profile info
[ -f "$PROFILE_DIR/profile-info.txt" ] && cat "$PROFILE_DIR/profile-info.txt"

echo ""
echo "Profile imported. Run './apply.sh --light' or './apply.sh --dark' to apply."
