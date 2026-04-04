#!/usr/bin/env bash
set -euo pipefail

setup_v2_extras() {
    log_info "Preparing v2 extras..."
    _source_legacy_module_v2 "setup-skills.sh"
    _source_legacy_module_v2 "setup-voice.sh"
    _source_legacy_module_v2 "setup-messaging.sh"
    _source_legacy_module_v2 "secure.sh"

    mkdir -p "${CLAWSPARK_DIR}"
    _seed_skills_config_v2
    _prepare_messaging_choice_v2

    log_info "Installing skills for v2..."
    setup_skills || log_warn "Skill installation had issues -- continuing."

    log_info "Configuring voice for v2..."
    setup_voice || log_warn "Voice setup had issues -- continuing."

    log_info "Configuring messaging for v2..."
    setup_messaging || log_warn "Messaging setup had issues -- continuing."

    log_info "Applying security hardening for v2..."
    secure_setup || log_warn "Security hardening had issues -- continuing."

    if declare -F _start_node_host >/dev/null; then
        if check_command systemctl && systemctl is-active --quiet clawspark-nodehost.service 2>/dev/null; then
            log_info "Node host already running via systemd."
        else
            log_info "Starting node host..."
            _start_node_host || log_warn "Node host failed to start -- OpenClaw will still run without exec tools."
        fi
    fi

    log_success "v2 extras complete."
}

_source_legacy_module_v2() {
    local module="$1"
    local module_path="${CLAWSPARK_REPO_DIR}/lib/${module}"

    if [[ ! -f "${module_path}" ]]; then
        log_warn "Legacy module not found: ${module}"
        return 0
    fi

    # shellcheck source=/dev/null
    source "${module_path}"
}

_seed_skills_config_v2() {
    local bundled="${SCRIPT_DIR}/configs/skills.yaml"
    local target="${CLAWSPARK_DIR}/skills.yaml"

    if [[ -f "${bundled}" && ! -f "${target}" ]]; then
        cp "${bundled}" "${target}"
        log_info "Seeded v2 skills config: ${target}"
    fi
}

_prepare_messaging_choice_v2() {
    if [[ -n "${FLAG_MESSAGING:-}" ]]; then
        FLAG_MESSAGING=$(to_lower "${FLAG_MESSAGING}")
    elif [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
        FLAG_MESSAGING="skip"
    else
        local msg_opts=("WhatsApp" "Telegram" "Both" "Skip")
        FLAG_MESSAGING=$(prompt_choice "Connect a messaging platform? (Web UI is always available)" msg_opts 3)
        FLAG_MESSAGING=$(to_lower "${FLAG_MESSAGING}")
    fi

    export FLAG_MESSAGING
    log_info "Messaging preference: ${FLAG_MESSAGING}"
}