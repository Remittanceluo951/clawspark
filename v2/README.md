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
- `custom` (OpenAI-compatible third-party endpoint)

## Main files

- `v2/install.sh` — new installer entrypoint.
- `v2/lib/detect-hardware.sh` — CPU/GPU-aware classification.
- `v2/lib/select-runtime.sh` — runtime, provider, and model selection.
- `v2/lib/setup-provider.sh` — local or API backend preparation.
- `v2/lib/setup-openclaw.sh` — provider-aware OpenClaw config.
- `v2/lib/setup-extras.sh` — reuses legacy skill, voice, messaging, and security modules.
- `v2/lib/verify.sh` — validation for both local and API modes.

## Notes

`v2` now reuses the stable legacy modules for skills, voice, messaging, and security hardening.

Runtime state is kept under `~/.clawspark-v2`, while OpenClaw configuration remains under `~/.openclaw`.

For `custom`, provide your own base URL, API key, and model ID. This is intended for OpenAI-compatible vendors, self-hosted gateways, or enterprise AI endpoints.

The root `clawspark` CLI is now v2-aware for profile detection, provider-aware status, and remote/custom model inspection. `v2` should still be treated as a preview track while broader command coverage continues to improve.
