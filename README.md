<h1 align="center">spectre-kde</h1>

<p align="center">
  <strong>A clean, reversible, reproducible KDE Plasma 6 setup with a polished macOS-inspired workflow — 100% native to KDE.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge"></a>
  <img alt="Plasma 6" src="https://img.shields.io/badge/KDE_Plasma-6.x-1d99f3?style=for-the-badge&logo=kde&logoColor=white">
  <img alt="Linux" src="https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=111827">
  <img alt="Shell" src="https://img.shields.io/badge/Made_with-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white">
</p>

<p align="center">
  <a href="https://github.com/bigwalkdoe/spectre-kde/actions/workflows/lint.yml"><img alt="Lint workflow" src="https://img.shields.io/github/actions/workflow/status/bigwalkdoe/spectre-kde/lint.yml?branch=main&style=flat-square&label=lint"></a>
  <a href="https://github.com/bigwalkdoe/spectre-kde/actions/workflows/authorship-check.yml"><img alt="Authorship workflow" src="https://img.shields.io/github/actions/workflow/status/bigwalkdoe/spectre-kde/authorship-check.yml?branch=main&style=flat-square&label=authorship"></a>
</p>

<p align="center">
  <sub><code>top menu bar · floating dock · clean desktop · reversible config · native Plasma scripting</code></sub>
</p>

---

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│  Global Menu      ▍▍▍ Pager        ↓↑  Wi-Fi  🔊  🔋  19:32                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                                CLEAN DESKTOP                                 │
│                         (no icons, native containment)                       │
│                                                                              │
│                    ╭────────────────────────────────────╮                    │
│                    │     ●  ●  ●  ●  ●  ●  ●   🗑  │                    │
│                    ╰────────────────────────────────────╯                    │
│                         centered, fit-to-content dock                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Contents

- [What spectre-kde is](#what-spectre-kde-is)
- [Features](#features)
- [Screenshots](#screenshots)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Component managers](#component-managers)
- [Safety & reversibility](#safety--reversibility)
- [Configuration & profiles](#configuration--profiles)
- [Testing](#testing)
- [Documentation](#documentation)
- [License](#license)

## What spectre-kde is

**spectre-kde** configures Fedora KDE (and other KDE Plasma 6 desktops) into a minimal, premium, macOS-inspired workspace while staying fully native to KDE. It favors Plasma’s own APIs, scripting, and config systems over third-party docks, hacks, or fragile shell replacements.

The project is built around a simple contract:
- **Native:** use official KDE/Plasma tools and scripting where possible
- **Reversible:** take timestamped backups and support rollback/reset workflows
- **Reproducible:** declarative-ish configs, profiles, and idempotent apply steps
- **Safe by default:** preflight/doctor checks, guarded operations, and testable scripts

> [!NOTE]
> Target environment is **KDE Plasma 6.x** on Linux. Scripts are designed to be run from a user session with access to the appropriate KDE tooling.

## Features

| Area | What it provides |
|---|---|
| **Layout** | Top menu bar (global menu, pager, network speed, tray, clock) and a centered, fit-to-content floating dock with pinned launchers |
| **Desktop** | Clean desktop containment (no desktop icons), wallpaper management, polished defaults |
| **Theming** | Orchis look-and-feel (light/dark), color schemes, icons, cursor, GTK 3/4, splash, optional SDDM theme assets |
| **Top bar widgets** | Configurable app menu, pager, network speed indicator (download+upload, compact), system tray, and clock |
| **System integration** | Autostart, notifications, night light, power profiles, fonts, KWin rules, keyboard shortcuts/profile helpers |
| **Operations** | Interactive menu, doctor/health/system-check, apply/quick-update, backup/rollback/reset/sync/status/detect flows |
| **Profiles** | Profile export/import and presets (e.g. `profiles/dev`) for repeatable setups |
| **Testing** | `scripts/run-tests.sh` runs all `scripts/test-*.sh` suites with stubbed KDE tools in temp dirs (no live Plasma session required) |

## Screenshots

A selection of captured states from `screenshots/` (see [`screenshots/README.md`](screenshots/README.md) for more):

| | |
|---|---|
| <img src="screenshots/desktop-dual-20260924.png" alt="Dual desktop layout" width="100%"> | <img src="screenshots/desktop-after-apply.png" alt="Desktop after apply" width="100%"> |
| <img src="screenshots/post-apply-20261117-194922.png" alt="Post-apply layout (latest)" width="100%"> | <img src="screenshots/baseline-check.png" alt="Baseline check" width="100%"> |

## Quick start

```bash
# Clone and enter
git clone https://github.com/bigwalkdoe/spectre-kde.git
cd spectre-kde

# Optional: check dependencies and environment first
./doctor.sh

# Interactive setup (recommended)
./menu.sh

# Or apply directly
./apply.sh --light   # Light theme
./apply.sh --dark    # Dark theme
```

Helpful first-run tools:
- `./welcome.sh` — guided tour / onboarding
- `./doctor.sh` — diagnose missing dependencies and common issues
- `./system-check.sh` — run combined checks (doctor + preflight + verify)

## Usage

### Core commands

| Command | Purpose |
|---|---|
| `./apply.sh [--light\|--dark]` | Apply the full spectre-kde configuration |
| `./quick-update.sh` | Reapply layout/dock/top-bar/tray-related updates quickly |
| `./menu.sh` | Interactive menu for common operations and component management |
| `./status.sh` | Show current state/status information |
| `./verify.sh` | Verify applied configuration and expected state |
| `./backup.sh` | Create a backup snapshot |
| `./rollback.sh` | Roll back to a previous backup |
| `./reset.sh` | Reset/restore options |
| `./sync.sh` | Sync current config/state back into the repo where supported |
| `./detect.sh` | Detect environment/session details |
| `./update.sh` | Update workflow helper |
| `./doctor.sh` | Diagnose dependencies and environment issues |
| `./health.sh` | Health dashboard |
| `./system-check.sh` | Combined checks |
| `./fix-issues.sh` | Attempt automated fixes for common issues |
| `./commands.sh` | Quick command reference |
| `./install-deps.sh` | Install dependencies (review before running) |

### Typical workflow

```bash
# 1) Inspect and validate
./doctor.sh
./detect.sh

# 2) Apply
./apply.sh --light

# 3) Iterate quickly on layout/dock/top-bar changes
./quick-update.sh

# 4) Verify and inspect
./verify.sh
./status.sh
```

## Component managers

Most components can be managed independently via `scripts/manage-*.sh`:

| Manager | Purpose |
|---|---|
| `scripts/manage-dock.sh` | Dock applications, position/behavior settings |
| `scripts/manage-topbar.sh` | Top bar widgets/layout toggles (app menu, pager, netspeed, tray, clock) |
| `scripts/manage-tray.sh` | System tray pinned items |
| `scripts/manage-wallpaper.sh` | Wallpaper settings (including per-monitor support) |
| `scripts/manage-autostart.sh` | Autostart applications |
| `scripts/manage-notifications.sh` | Notification settings |
| `scripts/manage-nightlight.sh` | Night Color (blue light filter) |
| `scripts/manage-kwin-rules.sh` | KWin window rules |
| `scripts/manage-shortcuts.sh` | Keyboard shortcuts / declared shortcuts helpers |
| `scripts/manage-fonts.sh` | Fonts, exclusions, font cache |
| `scripts/manage-icons.sh` | Icon theme |
| `scripts/manage-cursor.sh` | Cursor theme and size |
| `scripts/manage-gtk.sh` | GTK 3/4 theme integration |
| `scripts/manage-splash.sh` | Plasma splash screen theme |
| `scripts/manage-sddm.sh` | SDDM login screen status/install/reinstall helpers |
| `scripts/manage-power.sh` | Power profiles (performance/balanced/power saver) |
| `scripts/manage-profile.sh` | Profile-related operations |
| `scripts/clean-backups.sh` | Prune old timestamped backups (keep newest N) |

> [!TIP]
> Many managers modify config files used by `apply.sh` / `quick-update.sh`. After changes, re-run the appropriate apply command to see results in a live Plasma session.

## Safety & reversibility

- **Timestamped backups:** apply/update flows create backups so changes can be rolled back
- **Rollback/reset tooling:** `./rollback.sh`, `./reset.sh`, and backup cleanup utilities are included
- **Preflight/verification:** scripts and checks help catch missing dependencies or inconsistent state
- **Native mechanisms:** prefers Plasma scripting and KDE config tools over destructive or opaque hacks

When running on a live Plasma session, some changes require `plasmashell` restarts/reloads or layout reapplication; `apply.sh` / `quick-update.sh` handle the expected flows for this project.

## Configuration & profiles

- **Configs:** `config/applied-*.conf` snapshots capture applied state for KDE/GTK/fonts/power/notifications and related components
- **Profiles:** `profiles/` contains reusable presets (e.g. `profiles/dev/`) for dock/top bar/tray/autostart and related settings
- **Profile tools:** `scripts/export-profile.sh`, `scripts/import-profile.sh`, and `scripts/manage-profile.sh` support profile workflows
- **Assets:** wallpapers, SDDM theme assets, and desktop entries live under `assets/`

## Testing

```bash
./scripts/run-tests.sh
```

- Runs every `scripts/test-*.sh` suite and prints a summary
- Test suites stub external KDE tools they need and use temporary directories
- No live Plasma session is required
- CI runs the same entry point, so newly added `test-*.sh` files are picked up automatically

## Documentation

| Document | Purpose |
|---|---|
| [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) | Common issues, diagnostics, and recovery |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Development workflow and contribution guidelines |
| [`SECURITY.md`](SECURITY.md) | Security policy and reporting guidance |
| [`screenshots/README.md`](screenshots/README.md) | Screenshot catalog and context |
| [`AGENTS.md`](AGENTS.md) | Repository guidance for AI/code agents |

## License

MIT — see [`LICENSE`](LICENSE).

Scripts, documentation, and vendored wallpaper assets in this repository are covered by the project license. Upstream themes/assets (e.g. Orchis, FairyWren, Bibata, SDDM theme components) remain subject to their respective upstream licenses.

<p align="center">
  <sub><code>spectre-kde</code> · native Plasma 6 · reversible by design · <code>./doctor.sh</code> before you dive deep</sub>
</p>
