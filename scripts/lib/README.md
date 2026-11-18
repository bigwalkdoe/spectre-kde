# Shared Plasma Utilities Library

**File:** `scripts/lib/plasma.sh`

This library provides common utilities for interacting with KDE Plasma 6 configuration and runtime. It consolidates repeated patterns across scripts to reduce duplication and improve maintainability.

## Usage

Source the library in your script:

```bash
# shellcheck source=scripts/lib/plasma.sh
source "$ROOT/scripts/lib/plasma.sh"
```

The library exports all functions and color constants. After sourcing, functions like `log_ok`, `detect_dock_panel_id`, `write_panel_setting`, etc. are available.

## Color Constants

- `RED`, `GREEN`, `YELLOW`, `BLUE`, `NC` (No Color)

## Logging Helpers

| Function | Description |
|----------|-------------|
| `log_info` | Print info message (blue) |
| `log_ok` | Print success message (green) |
| `log_warn` | Print warning message (yellow) |
| `log_err` | Print error message (red, stderr) |

## Plasma Config Paths

| Function | Description |
|----------|-------------|
| `plasma_rc_file()` | Returns `~/.config/plasmashellrc` |
| `plasma_appletsrc_file()` | Returns `~/.config/plasma-org.kde.plasma.desktop-appletsrc` |

## Panel Detection

| Function | Description |
|----------|-------------|
| `get_panel_ids_from_appletsrc([file])` | Returns space-separated panel IDs from appletsrc |
| `detect_dock_panel_id([file])` | Returns dock panel ID (icontasks containment) or exits 1 |
| `extract_panel_ids_from_layout(output)` | Parses `panelIds=X,Y` from layout.js output |
| `get_dock_panel_id_from_layout(output)` | Returns second panel ID (dock) from layout output |
| `get_top_panel_id_from_layout(output)` | Returns first panel ID (top bar) from layout output |

## Config Helpers (Safe Wrappers)

| Function | Description |
|----------|-------------|
| `kwrite(file, --group ..., --key key, value)` | Safe `kwriteconfig6` wrapper (suppresses errors) |
| `kread(file, --group ..., --key key)` | Safe `kreadconfig6` wrapper (returns empty on missing) |

## PlasmaViews Panel Operations

| Function | Description |
|----------|-------------|
| `write_panel_setting(rc_file, panel_id, key, value)` | Write to `[PlasmaViews][Panel N]` |
| `write_panel_defaults(rc_file, panel_id, key, value)` | Write to `[PlasmaViews][Panel N][Defaults]` |
| `write_panel_subgroup(rc_file, panel_id, subgroup, key, value)` | Write to `[PlasmaViews][Panel N][Subgroup]` |
| `read_panel_setting(rc_file, panel_id, key)` | Read from `[PlasmaViews][Panel N]` |
| `get_panel_subgroups(rc_file, panel_id)` | Returns space-separated subgroup names (e.g., `Horizontal1920 Vertical1080`) |

## Plasmashell Helpers

| Function | Description |
|----------|-------------|
| `restart_plasmashell()` | Graceful restart of `plasma-plasmashell.service` |
| `is_plasma_session()` | Returns 0 if running in a Plasma session |
| `get_wallpaper_plugin(containment_id, [appletsrc])` | Returns wallpaper plugin for a containment |

## Example: Persist Dock View Settings

```bash
source "$ROOT/scripts/lib/plasma.sh"

DOCK_PANEL=$(detect_dock_panel_id)
write_panel_setting "$(plasma_rc_file)" "$DOCK_PANEL" "alignment" "132"
write_panel_defaults "$(plasma_rc_file)" "$DOCK_PANEL" "minLength" "-1"
write_panel_defaults "$(plasma_rc_file)" "$DOCK_PANEL" "maxLength" "-1"

for grp in $(get_panel_subgroups "$(plasma_rc_file)" "$DOCK_PANEL"); do
    [ "$grp" = "Defaults" ] && continue
    write_panel_subgroup "$(plasma_rc_file)" "$DOCK_PANEL" "$grp" "minLength" "-1"
    write_panel_subgroup "$(plasma_rc_file)" "$DOCK_PANEL" "$grp" "maxLength" "-1"
done
```

## Scripts Using This Library

- `apply.sh` — dock panel ID extraction, logging
- `quick-update.sh` — dock panel ID extraction, logging
- `scripts/enforce-dock-view-settings.sh` — dock panel detection
- `scripts/set-dock-view-settings.sh` — PlasmaViews config operations
- `scripts/test-lib-plasma.sh` — test suite

## Design Principles

1. **No side effects on source** — Only defines functions/variables
2. **Safe defaults** — Wrappers suppress errors, return empty on missing keys
3. **Plasma 6 native** — Uses `kwriteconfig6`/`kreadconfig6` and Plasma 6 paths
4. **Testable** — All functions work with stubbed KDE tools in test environment