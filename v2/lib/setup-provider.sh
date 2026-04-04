#!/usr/bin/env bash
set -euo pipefail

setup_provider_v2() {
    log_info "Preparing inference backend..."
    mkdir -p "${HOME}/.openclaw"

    if [[ "${PRIMARY_PROVIDER}" == "ollama" ]]; then
        setup_ollama_backend_v2
    else
        log_info "API backend selected; local inference install skipped."
        INFERENCE_API_URL="${API_BASE_URL}"
        export INFERENCE_API_URL
    fi

    _write_gateway_env_v2
    log_success "Provider backend ready."
}

setup_ollama_backend_v2() {
    if ! check_command ollama; then
        log_info "Ollama not found — installing..."
        if [[ "$(uname)" == "Darwin" ]]; then
            if check_command brew; then
                (brew install ollama) >> "${CLAWSPARK_V2_LOG}" 2>&1 &
                spinner $! "Installing Ollama..."
            else
                curl -fsSL https://ollama.com/install.sh | sh >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
            fi
        else
            curl -fsSL https://ollama.com/install.sh | sh >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
        fi
        hash -r 2>/dev/null || true
    fi

    if ! check_command ollama; then
        log_error "Ollama install failed."
        return 1
    fi

    if ! curl -sf http://127.0.0.1:11434/ &>/dev/null; then
        log_info "Starting Ollama service..."
        if check_command systemctl && systemctl is-enabled ollama &>/dev/null; then
            sudo systemctl start ollama >> "${CLAWSPARK_V2_LOG}" 2>&1 || true
        else
            nohup ollama serve >> "${CLAWSPARK_V2_DIR}/ollama.log" 2>&1 &
            echo $! > "${CLAWSPARK_V2_DIR}/ollama.pid"
        fi
    fi

    local attempt=0
    while (( attempt < 30 )); do
        if curl -sf http://127.0.0.1:11434/ &>/dev/null; then
            break
        fi
        attempt=$(( attempt + 1 ))
        sleep 1
    done

    if ! curl -sf http://127.0.0.1:11434/ &>/dev/null; then
        log_error "Ollama is not responding."
        return 1
    fi

    if ! ollama list 2>/dev/null | grep -qF "${SELECTED_MODEL_ID}"; then
        log_info "Pulling local model ${SELECTED_MODEL_ID}..."
        if ! ollama pull "${SELECTED_MODEL_ID}" 2>&1 | tee -a "${CLAWSPARK_V2_LOG}"; then
            log_error "Failed to pull ${SELECTED_MODEL_ID}"
            return 1
        fi
    else
        log_success "Local model already available."
    fi

    INFERENCE_API_URL="http://127.0.0.1:11434/v1"
    export INFERENCE_API_URL
}

_write_gateway_env_v2() {
    local env_file="${HOME}/.openclaw/gateway.env"
    mkdir -p "$(dirname "${env_file}")"
    : > "${env_file}"

    local npm_prefix_bin
    npm_prefix_bin="$(npm config get prefix 2>/dev/null)/bin"
    local computed_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    [[ -d "${npm_prefix_bin}" ]] && computed_path="${npm_prefix_bin}:${computed_path}"
    [[ -d "${HOME}/.npm-global/bin" ]] && computed_path="${HOME}/.npm-global/bin:${computed_path}"
    [[ -d "/snap/bin" ]] && computed_path="${computed_path}:/snap/bin"

    printf 'PATH=%s\n' "${computed_path}" >> "${env_file}"
    printf 'OPENCLAW_GATEWAY_OPENAI_COMPAT=true\n' >> "${env_file}"
    printf 'CLAWSPARK_V2_RUNTIME_MODE=%s\n' "${RUNTIME_MODE}" >> "${env_file}"
    printf 'CLAWSPARK_V2_PRIMARY_PROVIDER=%s\n' "${PRIMARY_PROVIDER}" >> "${env_file}"

    case "${PRIMARY_PROVIDER}" in
        ollama)
            printf 'OLLAMA_API_KEY=ollama\n' >> "${env_file}"
            printf 'OLLAMA_BASE_URL=http://127.0.0.1:11434\n' >> "${env_file}"
            ;;
        openai)
            printf 'OPENAI_API_KEY=%s\n' "${API_KEY}" >> "${env_file}"
            printf 'OPENAI_BASE_URL=%s\n' "${API_BASE_URL}" >> "${env_file}"
            ;;
        anthropic)
            printf 'ANTHROPIC_API_KEY=%s\n' "${API_KEY}" >> "${env_file}"
            printf 'ANTHROPIC_BASE_URL=%s\n' "${API_BASE_URL}" >> "${env_file}"
            ;;
        openrouter)
            printf 'OPENROUTER_API_KEY=%s\n' "${API_KEY}" >> "${env_file}"
            printf 'OPENROUTER_BASE_URL=%s\n' "${API_BASE_URL}" >> "${env_file}"
            ;;
        google)
            printf 'GOOGLE_API_KEY=%s\n' "${API_KEY}" >> "${env_file}"
            printf 'GOOGLE_BASE_URL=%s\n' "${API_BASE_URL}" >> "${env_file}"
            ;;
    esac

    if [[ -n "${FALLBACK_PROVIDER:-}" ]]; then
        printf 'CLAWSPARK_V2_FALLBACK_PROVIDER=%s\n' "${FALLBACK_PROVIDER}" >> "${env_file}"
        printf 'CLAWSPARK_V2_FALLBACK_MODEL=%s\n' "${FALLBACK_MODEL_ID}" >> "${env_file}"
    fi

    chmod 600 "${env_file}"
    log_info "gateway.env written for ${PRIMARY_PROVIDER}"
}
