#!/usr/bin/env bash
set -euo pipefail

setup_openclaw_v2() {
    log_info "Installing and configuring OpenClaw for v2..."
    _ensure_node_v2
    _install_openclaw_v2
    _write_openclaw_config_v2
    _run_onboard_v2
    log_success "OpenClaw v2 configuration complete."
}

_ensure_node_v2() {
    local required_major=22
    if check_command node; then
        local node_ver major
        node_ver=$(node -v 2>/dev/null | sed 's/^v//')
        major=$(echo "${node_ver}" | cut -d. -f1)
        if (( major >= required_major )); then
            log_success "Node.js v${node_ver} satisfies >= ${required_major}."
            return 0
        fi
    fi

    log_info "Installing Node.js ${required_major}.x..."
    if check_command apt-get; then
        (curl -fsSL "https://deb.nodesource.com/setup_${required_major}.x" | sudo -E bash - && sudo apt-get install -y nodejs) >> "${CLAWSPARK_V2_LOG}" 2>&1 &
        spinner $! "Installing Node.js..."
    elif check_command brew; then
        (brew install "node@${required_major}") >> "${CLAWSPARK_V2_LOG}" 2>&1 &
        spinner $! "Installing Node.js..."
    else
        log_error "No supported package manager found for Node.js install."
        return 1
    fi

    if ! check_command node; then
        log_error "Node.js installation failed."
        return 1
    fi
}

_install_openclaw_v2() {
    if check_command openclaw; then
        log_success "OpenClaw already installed."
        return 0
    fi

    log_info "Installing OpenClaw globally via npm..."
    (npm install -g openclaw@latest 2>>"${CLAWSPARK_V2_LOG}" || sudo npm install -g openclaw@latest) >> "${CLAWSPARK_V2_LOG}" 2>&1 &
    spinner $! "Installing OpenClaw..."
    hash -r 2>/dev/null || true

    if ! check_command openclaw; then
        log_error "OpenClaw install failed."
        return 1
    fi
}

_write_openclaw_config_v2() {
    local config_dir="${HOME}/.openclaw"
    local config_file="${config_dir}/openclaw.json"
    local auth_token

    mkdir -p "${config_dir}"
    chmod 700 "${config_dir}"

    auth_token=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n')
    [[ -f "${config_file}" ]] || echo '{}' > "${config_file}"

    openclaw config set gateway.mode local >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
    openclaw config set gateway.port 18789 >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
    openclaw config set gateway.auth.token "${auth_token}" >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
    openclaw config set tools.profile full >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
    openclaw config set agents.defaults.memorySearch.enabled false >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
    openclaw config set agents.defaults.workspace "${HOME}/workspace" >> "${CLAWSPARK_V2_LOG}" 2>&1 || true

    local default_model_ref
    default_model_ref=$(_provider_model_ref_v2 "${PRIMARY_PROVIDER}" "${SELECTED_MODEL_ID}")
    openclaw config set agents.defaults.model "${default_model_ref}" >> "${CLAWSPARK_V2_LOG}" 2>&1 || true

    python3 - "${config_file}" "${PRIMARY_PROVIDER}" "${SELECTED_MODEL_ID}" "${RUNTIME_MODE}" "${FALLBACK_PROVIDER:-}" "${FALLBACK_MODEL_ID:-}" <<'PY'
import json, sys
path, provider, model, runtime_mode, fallback_provider, fallback_model = sys.argv[1:7]
with open(path, 'r', encoding='utf-8') as fh:
    cfg = json.load(fh)

cfg.setdefault('tools', {})
cfg['tools']['profile'] = 'full'
cfg.setdefault('gateway', {})
cfg['gateway']['mode'] = 'local'
cfg.setdefault('agents', {}).setdefault('defaults', {})

def provider_ref(p, m):
    if p == 'ollama':
        return f'ollama/{m}'
    if p == 'openai':
        return f'openai/{m}'
    if p == 'anthropic':
        return f'anthropic/{m}'
    if p == 'openrouter':
        return f'openai/{m}'
    if p == 'google':
        return f'openai/{m}'
    return m

cfg['agents']['defaults']['model'] = provider_ref(provider, model)
cfg['clawsparkV2'] = {
    'runtimeMode': runtime_mode,
    'primaryProvider': provider,
    'primaryModel': model,
}
if fallback_provider and fallback_model:
    cfg['clawsparkV2']['fallbackProvider'] = fallback_provider
    cfg['clawsparkV2']['fallbackModel'] = fallback_model

cfg.setdefault('models', {})
cfg['models'].setdefault('providers', {})

if provider == 'ollama':
    cfg['models']['providers']['ollama'] = {
        'baseUrl': 'http://127.0.0.1:11434/v1',
        'api': 'openai-completions'
    }
elif provider in ('openai', 'openrouter', 'google'):
    provider_key = 'openai'
    cfg['models']['providers'][provider_key] = {
        'api': 'openai-completions'
    }
elif provider == 'anthropic':
    cfg['models']['providers']['anthropic'] = {
        'api': 'anthropic-messages'
    }

with open(path, 'w', encoding='utf-8') as fh:
    json.dump(cfg, fh, indent=2)
PY

    echo "${auth_token}" > "${config_dir}/.gateway-token"
    chmod 600 "${config_dir}/.gateway-token"
}

_provider_model_ref_v2() {
    local provider="$1"
    local model="$2"
    case "${provider}" in
        ollama) printf 'ollama/%s' "${model}" ;;
        openai) printf 'openai/%s' "${model}" ;;
        anthropic) printf 'anthropic/%s' "${model}" ;;
        openrouter) printf 'openai/%s' "${model}" ;;
        google) printf 'openai/%s' "${model}" ;;
        *) printf '%s' "${model}" ;;
    esac
}

_run_onboard_v2() {
    local env_file="${HOME}/.openclaw/gateway.env"
    if [[ -f "${env_file}" ]]; then
        set +e
        set -a
        source "${env_file}" 2>/dev/null
        set +a
        set -e
    fi

    openclaw onboard \
        --non-interactive \
        --accept-risk \
        --auth-choice skip \
        --skip-daemon \
        --skip-channels \
        --skip-skills \
        --skip-ui \
        --skip-health \
        >> "${CLAWSPARK_V2_LOG}" 2>&1 || {
        log_warn "openclaw onboard returned non-zero. This may be acceptable on reruns."
    }
}
