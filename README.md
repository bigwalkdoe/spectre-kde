# spectre-kde

**A clean, reversible, reproducible KDE Plasma 6 configuration with a polished macOS-inspired workflow — 100% native to KDE.**

> *Minimal + premium + restrained + native + fast.*  
> macOS interaction model + KDE/Linux functionality. KDE stability always wins over visual similarity.

```
┌──────────────────────────────────────────────────────────────┐
│  app menu      ▍▍▍         WiFi 🔊 🔋 19:32  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│                        CLEAN DESKTOP                         │
│                                                              │
│                  ╭──────────────────────────╮                │
│                  │ 🍎 ● ● ● ● ● ● ● ● 🗑 │                │
│                  ╰──────────────────────────╯                │
└──────────────────────────────────────────────────────────────┘
```

---

## About

**spectre-kde** transforms Fedora KDE (and other KDE Plasma 6 distributions) into a clean, macOS-like desktop environment without sacrificing KDE's power and flexibility. Every change is made through official KDE APIs, is fully reversible with automatic backups, and leaves your system in a safe, predictable state.

**Key Features:**
- 🖥️ **Native macOS-like UI** — Top menu bar, floating dock, clean desktop with no icons
- 🎨 **Beautiful theming** — Orchis look-and-feel, FairyWren icons, Bibata cursor
- 🔒 **Safe & reversible** — Automatic timestamped backups, instant rollback on failure
- 🛠️ **Fully configurable** — Interactive menu, per-app settings, declarative configs
- ⚡ **Fast & native** — Uses Plasma's native scripting API, no third-party docks or hacks
- 🌙 **Light & dark modes** — Easy switching between Orchis and Orchis-dark

---

## Quick Start

```bash
# Clone and enter
git clone https://github.com/bigwalkdoe/spectre-kde.git
cd spectre-kde

# Interactive setup (recommended)
./menu.sh

# Or apply directly
./apply.sh --light   # Light theme
./apply.sh --dark    # Dark theme
```

For first-time setup, run `./welcome.sh` for a guided tour, or `./doctor.sh` to check dependencies.

---

## All-in-One Tools

| Tool | Purpose |
|------|---------|
| `./menu.sh` | Interactive menu for all configuration options |
| `./health.sh` | Comprehensive system health dashboard |
| `./doctor.sh` | Diagnose dependencies and common issues |
| `./system-check.sh` | Run all checks (doctor + preflight + verify) |
| `./fix-issues.sh` | Auto-fix common issues |
| `./commands.sh` | Quick command reference |

---

## Testing

```bash
./scripts/run-tests.sh
```

Runs every `scripts/test-*.sh` suite and prints a summary. The suites stub the
KDE tools they need and use temporary directories, so no live Plasma session is
required. CI uses the same entry point, so a newly added `test-*.sh` file runs
on every push automatically.

## License

MIT — See [LICENSE](LICENSE). Scripts, documentation, and the vendored wallpaper are covered. Orchis, FairyWren, Bibata, and SDDM themes are from their respective upstream projects.
