# Troubleshooting

This guide covers common issues when using **spectre-kde** on KDE Plasma 6 systems.

## Quick checks

Start with these tools (they are safe to run and provide useful diagnostics):

```bash
./doctor.sh
./system-check.sh
./verify.sh
```

Useful variants:

```bash
./scripts/preflight-check.sh --light
./scripts/preflight-check.sh --dark
./verify.sh --no-health
./fix-issues.sh
```

- `doctor.sh`: checks environment, required tools, theme assets, and config directory permissions.
- `system-check.sh`: runs doctor, preflight checks (light/dark), and verification in one pass.
- `verify.sh`: compares applied state/config expectations and reports health/status issues.
- `fix-issues.sh`: attempts automated fixes for common problems (review output before continuing).

## Before applying changes

If you plan to run `apply.sh`, validate first:

```bash
./scripts/preflight-check.sh --light
# or
./scripts/preflight-check.sh --dark
```

You can also preview apply behavior without making changes:

```bash
./apply.sh --light --dry-run
./apply.sh --dark --dry-run
```

## Common issues

### 1. Not running in a KDE Plasma session

**Symptoms**
- `doctor.sh` reports Plasma session/display issues.
- Apply/verify commands fail early or behave unexpectedly.

**What to do**
- Run spectre-kde from a KDE Plasma 6 session (Wayland or X11).
- Ensure required Plasma tooling is installed (e.g. `plasmashell`, `kwriteconfig6`, Plasma apply tools).

### 2. Missing dependencies or KDE tools

**Symptoms**
- `doctor.sh` or preflight checks report missing commands/tools.
- Menu actions or component managers fail with “command not found”.

**What to do**
- Install dependencies using the project helper:

```bash
./install-deps.sh
```

- Re-run:

```bash
./doctor.sh
```

### 3. Missing theme assets (Orchis, icons, cursor)

**Symptoms**
- `doctor.sh` warns about missing Orchis/FairyWren/Bibata assets.
- Theme does not fully apply (colors/icons/cursor/look-and-feel mismatch).

**What to do**
- Install the required themes/assets for your distro.
- Re-run `./doctor.sh` and `./scripts/preflight-check.sh --light` or `--dark`.
- Apply again once assets are present.

### 4. Apply failed or desktop looks wrong after changes

**Symptoms**
- Partial theme/layout changes, unexpected panel behavior, or verification failures.

**What to do**
1. Run diagnostics:
   ```bash
   ./doctor.sh
   ./verify.sh
   ```
2. Try automated fixes (if appropriate):
   ```bash
   ./fix-issues.sh
   ```
3. Restore a known-good state using backups/rollback:
   ```bash
   ./rollback.sh
   ```

`apply.sh` is designed to use timestamped backups and rollback on failure paths, but a manual rollback is useful if the session is in a bad state.

### 5. Panels/widgets/layout issues

**Symptoms**
- Dock/top bar widgets missing, tray items not pinned as expected, or layout inconsistencies.

**What to do**
- Use the targeted managers instead of reapplying everything:
  ```bash
  ./scripts/manage-dock.sh
  ./scripts/manage-topbar.sh
  ./scripts/manage-tray.sh
  ./scripts/manage-wallpaper.sh
  ```
- For a quick targeted refresh (depending on what changed), use:
  ```bash
  ./quick-update.sh
  ```
- Re-run `./verify.sh` to confirm the current state.

### 6. Permission or config path issues

**Symptoms**
- `doctor.sh` reports `~/.config` or `~/.local/share` not writable.
- Scripts cannot write backups/config files.

**What to do**
- Fix ownership/permissions for your user on the affected directories.
- Re-run `./doctor.sh` before applying changes again.

## Backups and recovery

- **Create a backup**: `./backup.sh`
- **Rollback to previous backup**: `./rollback.sh`
- **Restore/reset options**: `./reset.sh`

Backups are stored under `~/.config/kde-backups/` (timestamped directories). If you are experimenting, create a backup before major changes.

## Getting more detail

- Check script output carefully; many scripts print actionable hints.
- Run specific checks related to the area you changed (e.g. preflight for apply issues, verify for state mismatches).
- If you are developing or modifying scripts, run:
  ```bash
  ./scripts/run-tests.sh
  ```
  to confirm repository behavior remains consistent.
