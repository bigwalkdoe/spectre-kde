#!/usr/bin/env bash
# spectre-kde -- export-profile.sh
# Export current configuration as a profile

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE_NAME="${1:-default}"
PROFILE_DIR="$ROOT/profiles/$PROFILE_NAME"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Exporting profile: $PROFILE_NAME"

mkdir -p "$PROFILE_DIR"

# Export dock configuration
cp "$ROOT/scripts/dock-launchers.list" "$PROFILE_DIR/" 2>/dev/null || true
cp "$ROOT/scripts/dock-config" "$PROFILE_DIR/" 2>/dev/null || true

# Export autostart
cp "$ROOT/scripts/autostart.list" "$PROFILE_DIR/" 2>/dev/null || true

# Export theme markers
[ -f "$ROOT/.applied-light" ] && cp "$ROOT/.applied-light" "$PROFILE_DIR/"
[ -f "$ROOT/.applied-dark" ] && cp "$ROOT/.applied-dark" "$PROFILE_DIR/"

# Export metadata
cat > "$PROFILE_DIR/profile-info.txt" << EOF
Profile: $PROFILE_NAME
Exported: $(date)
Hostname: $(hostname)
User: $USER
EOF

echo "Profile exported to: $PROFILE_DIR"
echo ""
echo "To import: ./scripts/import-profile.sh $PROFILE_NAME"
