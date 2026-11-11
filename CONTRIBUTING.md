# Contributing to spectre-kde

Thanks for contributing to **spectre-kde**. This project applies and manages a macOS-inspired KDE Plasma 6 configuration using native KDE tools and shell scripts, with an emphasis on safety, reversibility, and consistency.

## Before you start

- Read [`README.md`](README.md) for project goals and usage.
- Read [`AGENTS.md`](AGENTS.md) (repo guidance) and follow the development workflow: **inspect → plan → implement → test → verify → review**.
- Understand the area you’re changing before editing: scripts, config snapshots, tests, and docs are tightly related.

## Repository overview

- **Root scripts**: user-facing entry points (e.g. `apply.sh`, `menu.sh`, `doctor.sh`, `verify.sh`, `backup.sh`, `rollback.sh`, `reset.sh`, `system-check.sh`).
- **`scripts/`**: component managers, helpers, and test suites (`manage-*.sh`, `test-*.sh`, utilities).
- **`config/`**: configuration snapshots/templates applied by the scripts.
- **`assets/`**: bundled assets (e.g. wallpapers/themes support files where applicable).
- **`profiles/`**: exported/imported profile data (may be empty in a fresh checkout).

## Development guidelines

- **Keep changes focused**: solve the stated problem with minimal, targeted edits.
- **Follow existing patterns**: match naming, shell style, logging/output conventions, and file layout used by nearby scripts.
- **Prefer safe, reversible behavior**: this project relies on backups/rollback and validation flows—avoid changes that weaken those guarantees.
- **Do not modify unrelated behavior**: especially in `apply.sh`, `verify.sh`, backup/restore logic, and menu dispatch.
- **Avoid destructive operations** unless explicitly required and clearly communicated.

## Running checks and tests

### Test suite (recommended)

Run all tests:

```bash
./scripts/run-tests.sh
```

Run specific suites:

```bash
./scripts/run-tests.sh test-menu.sh test-verify.sh
```

Notes:
- Test suites live in `scripts/test-*.sh`.
- Tests are designed to run without a live Plasma session (they use temp directories and stub external KDE tools where needed).
- `scripts/run-tests.sh` is the same entry point used by CI; adding a new `scripts/test-*.sh` file makes it part of the standard suite.

### Diagnostics / verification tools

Depending on your change, also run relevant checks:

```bash
./doctor.sh
./scripts/preflight-check.sh --light
./scripts/preflight-check.sh --dark
./verify.sh --no-health
./system-check.sh
```

Use the checks that match the code you changed (e.g. menu changes → `test-menu.sh`, verify logic → `test-verify.sh`, apply/preflight changes → preflight/apply-related checks).

## Adding or updating tests

- Place new suites in `scripts/` as `test-<area>.sh` and make them executable.
- Follow existing test patterns:
  - Use a temp working directory (`mktemp -d`) and clean up with `trap`.
  - Stub external commands/tools in a temp `bin/` and prepend it to `PATH` when needed.
  - Print clear `ok`/`FAIL` lines and exit non-zero on failure.
  - Keep tests deterministic and independent of the user’s real KDE session/config.
- Update tests when behavior intentionally changes.
- Prefer testing observable script behavior (dispatch, generated config, validation outcomes) over implementation details.

## Documentation changes

- Keep `README.md` accurate for user-facing workflows and commands.
- Add or update focused docs (e.g. `CONTRIBUTING.md`, `TROUBLESHOOTING.md`) when they improve clarity without duplicating large sections unnecessarily.
- Use concrete commands and file paths that exist in this repository.

## Submitting changes

- Review your diff (`git diff`) and status (`git status`) before committing.
- Do not commit secrets, credentials, or machine-specific private data.
- Prefer small, reviewable commits with clear messages.
- In your PR/summary, include:
  - what changed and why
  - what you tested/verified (commands and results)
  - any follow-up work or known limitations
