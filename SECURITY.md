# Security Policy

## Supported versions

`spectre-kde` is provided on a best-effort basis. Security-related fixes, when applicable, are made in the latest state of the repository.

## Reporting a vulnerability

If you discover a security issue (for example, unsafe command execution, privilege escalation risks, or exposure of sensitive data through scripts/configuration), please report it responsibly:

1. **Preferred:** Use GitHub’s private vulnerability reporting for this repository if it is enabled.
2. **If private reporting is not available:** Open a GitHub issue with enough detail to reproduce and assess the impact, but avoid posting secrets, credentials, or exploit details that should remain private.

When reporting, include:
- affected script(s)/file(s) and version/commit if known
- reproduction steps or proof-of-concept (sanitized)
- expected vs. actual behavior
- potential impact and any suggested mitigation

## Scope notes

- This project consists primarily of local KDE Plasma configuration scripts and assets.
- Review scripts before running them, especially when using `sudo` or modifying system/user configuration.
- Do not include passwords, tokens, or private machine data in bug reports or commits.
