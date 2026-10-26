#!/usr/bin/env bash
# spectre-kde -- scripts/export-config.sh
# Export current live configuration to a tarball
# Usage: ./scripts/export-config.sh [output-dir]

set -euo pipefail

CFG="$HOME/.config"
OUTDIR="${1:-$HOME}"
TS=$(date +%Y%m%d-%H%M%S)
OUT="$OUTDIR/spectre-kde-config-$TS.tar.gz"

FILES=(
    plasma-org.kde.plasma.desktop-appletsrc
    plasmashellrc
    kdeglobals
    kwinrc
    kwinrulesrc
    kglobalshortcutsrc
    kcminputrc
    ksplashrc
    plasmarc
    dolphinrc
    gwenviewrc
    kwinoutputconfig.json
    plasma-localerc
    baloofilerc
    powermanagementprofilesrc
    plasma-notifications.conf
)

echo "Exporting spectre-kde configuration..."
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/spectre-kde-config"

for f in "${FILES[@]}"; do
    if [ -f "$CFG/$f" ]; then
        cp -a "$CFG/$f" "$TMPDIR/spectre-kde-config/"
        echo "  ✓ $f"
    fi
done

# GTK
for g in gtk-3.0 gtk-4.0; do
    if [ -f "$CFG/$g/settings.ini" ]; then
        mkdir -p "$TMPDIR/spectre-kde-config/$g"
        cp -a "$CFG/$g/settings.ini" "$TMPDIR/spectre-kde-config/$g/"
        echo "  ✓ $g/settings.ini"
    fi
done

# Fontconfig
if [ -f "$CFG/fontconfig/fonts.conf" ]; then
    mkdir -p "$TMPDIR/spectre-kde-config/fontconfig"
    cp -a "$CFG/fontconfig/fonts.conf" "$TMPDIR/spectre-kde-config/fontconfig/"
    echo "  ✓ fontconfig/fonts.conf"
fi

# Autostart
if [ -d "$CFG/autostart" ]; then
    cp -a "$CFG/autostart" "$TMPDIR/spectre-kde-config/"
    echo "  ✓ autostart/"
fi

# SDDM config if accessible
if [ -f /etc/sddm.conf.d/theme.conf ]; then
    mkdir -p "$TMPDIR/spectre-kde-config/sddm"
    cp -a /etc/sddm.conf.d/theme.conf "$TMPDIR/spectre-kde-config/sddm/" 2>/dev/null && echo "  ✓ sddm/theme.conf" || true
fi

tar -czf "$OUT" -C "$TMPDIR" spectre-kde-config
rm -rf "$TMPDIR"

echo ""
echo "Exported to: $OUT"
echo "Size: $(du -h "$OUT" | cut -f1)"
