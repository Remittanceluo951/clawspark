# Contributing

Thanks for contributing to `clawspark`.

## License Reminder

By contributing to this repository, you agree that your contributions are
submitted under the repository's license and may be used, modified,
distributed, and commercially licensed by the repository owner/copyright
holder. Third parties do not receive commercial rights unless separately
authorized in writing by the copyright holder.

## Development Workflow

1. create a branch from `main`
2. make focused changes
3. run validation locally
4. open a pull request with a clear summary

## Local Validation

Run the core checks before opening a pull request:

```bash
bash -n ./clawspark
bash ./tests/run.sh
npm pack --dry-run
```

## Change Guidelines

- keep Bash changes portable and explicit
- preserve existing CLI compatibility where possible
- update docs when changing installer, provider, or release behavior
- add or update Bats coverage for CLI-facing changes
- avoid committing secrets, tokens, or machine-specific credentials

## Pull Request Checklist

- [ ] code is scoped to one clear change
- [ ] tests were added or updated when needed
- [ ] `bash ./tests/run.sh` passes
- [ ] `npm pack --dry-run` passes when packaging is affected
- [ ] docs were updated for user-facing changes
- [ ] changelog updated when appropriate

## Release Notes

Version tags must match `package.json` exactly, for example `v2.0.0`.
Publishing to npm is handled by GitHub Actions and requires the `NPM_TOKEN` secret for the `hitechclaw` npm account.
Use `bash scripts/release.sh patch|minor|major [--push]` to run local validation, bump the version, create the tag, and optionally push it.
