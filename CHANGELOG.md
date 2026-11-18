# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Shared Plasma utilities library (`scripts/lib/plasma.sh`) with common functions for:
  - Panel detection (dock panel via icontasks, panel IDs from layout output)
  - Configuration helpers (safe kwriteconfig6/kreadconfig6 wrappers, PlasmaViews panel settings)
  - Plasmashell management (restart, session detection)
  - Logging helpers with colors
- New test suite: `scripts/test-lib-plasma.sh` for the shared library

### Changed
- **Refactored**: `scripts/enforce-dock-view-settings.sh` now uses shared library for dock panel detection
- **Refactored**: `scripts/set-dock-view-settings.sh` now uses shared library for PlasmaViews config operations
- **Refactored**: `apply.sh` now uses shared library for dock panel ID extraction from layout output
- **Refactored**: `quick-update.sh` now uses shared library for dock panel ID extraction and logging
- **Tests**: Updated `test-enforce-dock-view-settings.sh` and `test-set-dock-view-settings.sh` to include shared library

### Fixed
- Dock panel detection now correctly handles nested Applets sections in appletsrc
- Removed hardcoded path in `scripts/clean-plasmashellrc.sh` that caused CI failure

## [1.1.0] - 2026-11-18

### Added
- Configurable top-bar network speed modes (`dual`, `download`, `upload`) via `TOPBAR_NETSPEED_MODE`
- Optional network speed labels via `TOPBAR_NETSPEED_LABELS`
- New manager commands: `manage-topbar.sh netspeed-mode`, `manage-topbar.sh netspeed-labels`
- Centralized dock panel view persistence: `scripts/set-dock-view-settings.sh`
- Runtime dock view normalization: `scripts/enforce-dock-view-settings.sh`
- Interactive menu integration for dock config, top-bar management, and profile workflows
- Profile name validation (letters, digits, dot, underscore, hyphen)
- Profile show/info command in `manage-profile.sh`
- Dock config `set` command in `manage-dock.sh`
- Expanded test suites:
  - `test-clean-plasmashellrc.sh`
  - `test-diff-config.sh`
  - `test-enforce-dock-view-settings.sh`
  - `test-manage-profile.sh`
  - `test-preflight-check.sh`
  - `test-resolve-launchers.sh`
  - `test-restore-backup.sh`
  - `test-set-dock-view-settings.sh`
  - `test-set-panel-visibility.sh`
  - `test-verify.sh` (extended)
  - `test-menu.sh` (updated for new profile flows)

### Changed
- `apply.sh` / `quick-update.sh` now persist dock view settings using centralized script
- `verify.sh` checks live dock `lengthMode` and mode-aware netspeed config
- `scripts/topbar-config` now includes `TOPBAR_NETSPEED_MODE` and `TOPBAR_NETSPEED_LABELS`
- `README.md` updated with new configuration keys, manager descriptions, and menu integration notes
- `TROUBLESHOOTING.md` expanded with netspeed/dock/profile diagnostics and recovery procedures
- Menu system (`menu.sh`) now includes top-bar management submenu and improved profile workflows

### Fixed
- `scripts/restore-backup.sh` direct-run no-backup handling for `set -euo pipefail`
- CI shellcheck workflow now passes with new scripts
- All 42 test suites pass

## [1.0.0] - 2026-09-24

### Added
- Initial release
- macOS-inspired KDE Plasma 6 configuration
- Top menu bar with global menu, pager, network speed, tray, clock
- Centered, fit-to-content floating dock with pinned launchers
- Orchis look-and-feel (light/dark), color schemes, icons, cursor
- GTK 3/4 theme integration, splash screen, optional SDDM theme
- Reversible configuration with backup/rollback/reset/sync
- Profile system (export/import presets)
- Comprehensive test suite with stubbed KDE tools
- CI workflows for linting and testing
- Documentation (README, TROUBLESHOOTING, CONTRIBUTING, SECURITY)