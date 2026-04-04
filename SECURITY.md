# Security Policy

## Supported Versions

The latest release on `main` is the supported line for fixes and security updates.

| Version | Supported |
|---|---|
| 2.x | Yes |
| < 2.0.0 | No |

## Reporting a Vulnerability

Please do not open a public issue for security-sensitive reports.

Report vulnerabilities by contacting the maintainers through a private channel before public disclosure. Include:

- affected version
- impact summary
- reproduction steps
- proof of concept if available
- suggested mitigation if known

Expected response targets:

- initial acknowledgement: within 3 business days
- triage decision: within 7 business days
- remediation status update: as available during investigation

## Security Scope

Security-sensitive areas in this repository include:

- installer privilege boundaries
- generated auth tokens and secret handling
- gateway exposure and localhost binding
- sandbox hardening
- skill installation and skill audit coverage
- remote provider credential handling in `~/.openclaw/gateway.env`
- CI/CD publishing credentials for npm and GitHub releases

## Operational Guidance

Before publishing a release:

1. run `bash ./tests/run.sh`
2. run `npm pack --dry-run`
3. confirm npm publishing uses the `hitechclaw` account
4. confirm the `NPM_TOKEN` GitHub secret is present
5. verify the release tag matches `package.json` exactly
