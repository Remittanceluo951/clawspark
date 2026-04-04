# Changelog

All notable changes to `clawspark` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Installer now configures OpenClaw Control UI with `allowedOrigins=["*"]` by default for Caddy, Tailscale, and other reverse proxies.
- `clawspark update` now migrates existing installations to the wildcard Control UI origin policy.
- Tailscale setup now preserves wildcard Control UI origin settings instead of replacing them with a single remote origin.
- Gateway startup now uses an explicit `--port 18789` across installer and runtime fallback flows.
- `clawspark update` now refreshes `clawspark-gateway.service` and `clawspark-nodehost.service` so older installs receive the latest startup and restart settings.

### Added
- Changelog tracking for future releases.
- Custom non-commercial-use license allowing individuals and organizations to
    use the software for strictly non-commercial purposes only.
- Explicit prohibition on commercialization, commercial consulting, and other
    for-profit use by third parties without separate permission.
- `NOTICE` file summarizing the repository's non-commercial-use terms.
- `COMMERCIAL-LICENSE.md` explaining that commercial rights require a
    separate written agreement.
- Documentation notes clarifying that GitHub and npm availability do not grant
    commercial rights.
- npm packaging metadata via `package.json` and `.npmignore`.
- GitHub Actions workflow for publishing public npm releases from version tags.
- Release validation that checks tag/version alignment before npm publish.
- npm publish hardening with owner validation for the `hitechclaw` account and provenance-enabled releases.
- Automated GitHub Releases from version tags with attached npm tarballs.
- Continuous integration workflow for pushes and pull requests covering syntax, package validation, and tests.
- Repository governance files for security reporting, contribution workflow, and code ownership.
- Release helper script for validated version bumps and tag creation.

## [2.1.1] - 2026-04-04

### Changed
- Updated npm package metadata so the published package page points to `https://clawspark.hitechclaw.com`.
- Clarified the npm package description to state that use is limited to strictly non-commercial purposes.
- Updated npm-facing README content to reference the scoped package `@hitechclaw/clawspark` while keeping the installed CLI command as `clawspark`.

## [2.0.0] - 2026-04-04

### Added
- Initial `clawspark` CLI for installing and managing a local OpenClaw stack.
- Hardware-aware model selection and multi-model support for chat, vision, and optional image generation.
- Skills management, security audit flow, diagnostics, dashboard setup, MCP integration, sandbox controls, and Tailscale support.
- Documentation for installation, tutorial, and configuration workflows.
- Automated Bats test suites for CLI, security, shared helpers, and skills behavior.

### Changed
- Refined install and web deployment scripts for the public release flow.
- Updated repository metadata, deployment settings, and project documentation.

[Unreleased]: https://github.com/thanhan92-f1/clawspark/compare/main...HEAD
[2.1.1]: https://github.com/thanhan92-f1/clawspark/releases/tag/v2.1.1
[2.0.0]: https://github.com/thanhan92-f1/clawspark/releases/tag/v2.0.0