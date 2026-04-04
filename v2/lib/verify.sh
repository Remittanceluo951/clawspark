#!/usr/bin/env bash
set -euo pipefail

verify_v2_installation() {
    log_info "Running v2 verification checks..."
    hr

    local pass=0
    local fail=0

    _check_pass() {
        printf '  %s✓%s %s\n' "${GREEN}" "${RESET}" "$1"
        pass=$(( pass + 1 ))
    }

    _check_fail() {
        printf '  %s✗%s %s\n' "${RED}" "${RESET}" "$1"
        fail=$(( fail + 1 ))
    }

    _check_pass "Runtime mode: ${RUNTIME_MODE}"
    _check_pass "Primary provider: ${PRIMARY_PROVIDER}"
    _check_pass "Default model: ${SELECTED_MODEL_ID}"

    if check_command openclaw; then
        _check_pass "OpenClaw installed: $(openclaw --version 2>/dev/null || echo unknown)"
    else
        _check_fail "OpenClaw not installed"
    fi

    if [[ "${PRIMARY_PROVIDER}" == "ollama" ]]; then
        if curl -sf http://127.0.0.1:11434/ &>/dev/null; then
            _check_pass "Ollama API responding"
        else
            _check_fail "Ollama API not responding"
        fi

        if check_command ollama && ollama list 2>/dev/null | grep -qF "${SELECTED_MODEL_ID}"; then
            _check_pass "Local model available in Ollama"
        else
            _check_fail "Local model missing in Ollama"
        fi
    else
        local env_file="${HOME}/.openclaw/gateway.env"
        if [[ -f "${env_file}" ]]; then
            _check_pass "gateway.env written for API provider"
        else
            _check_fail "gateway.env missing"
        fi

        case "${PRIMARY_PROVIDER}" in
            openai)
                grep -q '^OPENAI_API_KEY=' "${env_file}" 2>/dev/null && _check_pass "OpenAI API key configured" || _check_fail "OpenAI API key missing"
                ;;
            anthropic)
                grep -q '^ANTHROPIC_API_KEY=' "${env_file}" 2>/dev/null && _check_pass "Anthropic API key configured" || _check_fail "Anthropic API key missing"
                ;;
            openrouter)
                grep -q '^OPENROUTER_API_KEY=' "${env_file}" 2>/dev/null && _check_pass "OpenRouter API key configured" || _check_fail "OpenRouter API key missing"
                ;;
            google)
                grep -q '^GOOGLE_API_KEY=' "${env_file}" 2>/dev/null && _check_pass "Google API key configured" || _check_fail "Google API key missing"
                ;;
        esac
    fi

    local config_file="${HOME}/.openclaw/openclaw.json"
    if [[ -f "${config_file}" ]]; then
        _check_pass "OpenClaw config present"
    else
        _check_fail "OpenClaw config missing"
    fi

    if [[ -f "${CLAWSPARK_DIR}/skills.yaml" ]]; then
        _check_pass "v2 skills config present"
    else
        _check_fail "v2 skills config missing"
    fi

    if [[ -f "${HOME}/.openclaw/skills/local-whisper/config.json" ]]; then
        _check_pass "Voice config present"
    else
        _check_fail "Voice config missing"
    fi

    if [[ -f "${CLAWSPARK_DIR}/token" ]]; then
        _check_pass "Security token generated"
    else
        _check_fail "Security token missing"
    fi

    if [[ "${FLAG_MESSAGING:-skip}" == "skip" || "${MESSAGING_CHOICE:-skip}" == "skip" ]]; then
        _check_pass "Messaging setup skipped"
    else
        _check_pass "Messaging configured: ${MESSAGING_CHOICE:-${FLAG_MESSAGING}}"
    fi

    if [[ -f "${CLAWSPARK_DIR}/gateway.pid" ]]; then
        local gateway_pid
        gateway_pid=$(cat "${CLAWSPARK_DIR}/gateway.pid" 2>/dev/null || echo "")
        if [[ -n "${gateway_pid}" ]] && kill -0 "${gateway_pid}" 2>/dev/null; then
            _check_pass "Gateway process running"
        else
            _check_fail "Gateway process not running"
        fi
    else
        _check_fail "Gateway PID file missing"
    fi

    if [[ -f "${CLAWSPARK_DIR}/node.pid" ]]; then
        local node_pid
        node_pid=$(cat "${CLAWSPARK_DIR}/node.pid" 2>/dev/null || echo "")
        if [[ -n "${node_pid}" ]] && kill -0 "${node_pid}" 2>/dev/null; then
            _check_pass "Node host running"
        else
            _check_fail "Node host not running"
        fi
    else
        _check_fail "Node host PID file missing"
    fi

    printf '\n'
    if (( fail == 0 )); then
        log_success "All ${pass} verification checks passed."
    else
        log_warn "${pass} checks passed, ${fail} failed."
    fi
}
