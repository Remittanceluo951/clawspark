# Changelog

All notable changes to `clawspark` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Changelog tracking for future releases.
- npm packaging metadata via `package.json` and `.npmignore`.
- GitHub Actions workflow for publishing public npm releases from version tags.
- Release validation that checks tag/version alignment before npm publish.
- npm publish hardening with owner validation for the `hitechclaw` account and provenance-enabled releases.

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
[2.0.0]: https://github.com/thanhan92-f1/clawspark/releases/tag/v2.0.0