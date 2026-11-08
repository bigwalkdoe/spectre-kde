# `dev` profile

Developer-focused spectre-kde preset.

**Includes:** dev-loop dock order (`dock-launchers.list`), `dock-config`, `topbar-config` with `TOPBAR_SHOW_NETSPEED=true`, `tray-config.js`, and `autostart.list`.

**Apply:**
```bash
./scripts/import-profile.sh dev
./quick-update.sh   # or: ./apply.sh --light / ./apply.sh --dark
```

**Update snapshot:** after tuning your setup, `./scripts/export-profile.sh dev` (overwrites this profile with your current config).