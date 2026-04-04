# clawspark v2

`v2/` is a CPU-friendly and provider-aware installer track for `clawspark`.

## Goals

- Support machines with **CPU only**, not just GPU-first setups.
- Allow **third-party API providers** as primary inference backends.
- Keep **hybrid mode** available for local + cloud fallback.
- Preserve OpenClaw-based workflow while reducing hard dependency on Ollama.

## Runtime modes

- `local-gpu` — local Ollama on GPU hardware.
- `local-cpu` — local Ollama on CPU-first hosts.
- `api-only` — no local model install, use provider API directly.
- `hybrid` — combine local and remote providers.

## Providers

Current provider catalog is in `v2/configs/providers.yaml`.

Initial providers:

- `ollama`
- `openai`
- `anthropic`
- `openrouter`
- `google`

## Main files

- `v2/install.sh` — new installer entrypoint.
- `v2/lib/detect-hardware.sh` — CPU/GPU-aware classification.
- `v2/lib/select-runtime.sh` — runtime, provider, and model selection.
- `v2/lib/setup-provider.sh` — local or API backend preparation.
- `v2/lib/setup-openclaw.sh` — provider-aware OpenClaw config.
- `v2/lib/verify.sh` — validation for both local and API modes.

## Notes

This is a focused v2 foundation, not a full replacement for the current root installer yet.
Messaging, dashboard, skills, sandbox, and systemd can be wired in after provider mode is stabilized.
