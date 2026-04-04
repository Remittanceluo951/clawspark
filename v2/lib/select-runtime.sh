#!/usr/bin/env bash
set -euo pipefail

select_runtime_v2() {
    log_info "Selecting runtime mode for v2..."

    local runtime_options=()
    local default_idx=0

    if [[ "${HW_ACCELERATION:-cpu}" == "gpu" ]]; then
        runtime_options=("local-gpu" "local-cpu" "hybrid" "api-only")
        default_idx=0
    else
        runtime_options=("local-cpu" "api-only" "hybrid")
        default_idx=0
    fi

    if [[ -n "${FLAG_RUNTIME_MODE:-}" ]]; then
        RUNTIME_MODE="${FLAG_RUNTIME_MODE}"
    else
        RUNTIME_MODE=$(prompt_choice "Choose deployment mode" runtime_options "${default_idx}")
    fi

    RUNTIME_MODE=$(to_lower "${RUNTIME_MODE}")
    export RUNTIME_MODE
    log_success "Runtime mode: ${RUNTIME_MODE}"
}

select_provider_v2() {
    log_info "Selecting inference provider..."

    local provider_options=()
    local default_idx=0

    case "${RUNTIME_MODE}" in
        local-gpu|local-cpu)
            provider_options=("ollama")
            default_idx=0
            ;;
        api-only|hybrid)
            provider_options=("openai" "anthropic" "openrouter" "google" "custom")
            default_idx=0
            ;;
        *)
            provider_options=("ollama")
            default_idx=0
            ;;
    esac

    if [[ -n "${FLAG_PROVIDER:-}" ]]; then
        PRIMARY_PROVIDER="${FLAG_PROVIDER}"
    else
        PRIMARY_PROVIDER=$(prompt_choice "Choose primary provider" provider_options "${default_idx}")
    fi

    PRIMARY_PROVIDER=$(to_lower "${PRIMARY_PROVIDER}")
    export PRIMARY_PROVIDER
    log_success "Primary provider: ${PRIMARY_PROVIDER}"
}

select_model_v2() {
    log_info "Selecting default model..."

    local model_options=()
    local model_ids=()
    local default_idx=0

    case "${PRIMARY_PROVIDER}" in
        ollama)
            if [[ "${RUNTIME_MODE}" == "local-cpu" ]]; then
                if [[ "${HW_CPU_PROFILE}" == "cpu-large" ]]; then
                    model_ids=("qwen2.5:14b-instruct-q4_K_M" "qwen2.5:7b-instruct-q4_K_M" "llama3.1:8b-instruct-q4_K_M")
                    model_options=(
                        "qwen2.5:14b-instruct-q4_K_M - best CPU quality for 32GB+ RAM"
                        "qwen2.5:7b-instruct-q4_K_M - balanced CPU default"
                        "llama3.1:8b-instruct-q4_K_M - stable general assistant"
                    )
                    default_idx=1
                elif [[ "${HW_CPU_PROFILE}" == "cpu-medium" ]]; then
                    model_ids=("qwen2.5:7b-instruct-q4_K_M" "llama3.1:8b-instruct-q4_K_M" "phi4-mini")
                    model_options=(
                        "qwen2.5:7b-instruct-q4_K_M - recommended for 16GB CPUs"
                        "llama3.1:8b-instruct-q4_K_M - general purpose CPU model"
                        "phi4-mini - lightweight and responsive"
                    )
                    default_idx=0
                else
                    model_ids=("phi4-mini" "qwen2.5:3b-instruct-q4_K_M" "llama3.2:3b")
                    model_options=(
                        "phi4-mini - lowest RAM recommendation"
                        "qwen2.5:3b-instruct-q4_K_M - compact instruct model"
                        "llama3.2:3b - small local fallback"
                    )
                    default_idx=0
                fi
            else
                model_ids=("qwen3.5:35b-a3b" "qwen3-coder:30b" "glm-4.7-flash")
                model_options=(
                    "qwen3.5:35b-a3b - default GPU local model"
                    "qwen3-coder:30b - coding focused"
                    "glm-4.7-flash - faster compact option"
                )
                default_idx=0
            fi
            ;;
        openai)
            model_ids=("gpt-4.1" "gpt-4.1-mini" "gpt-5-mini")
            model_options=(
                "gpt-4.1 - strong general purpose API model"
                "gpt-4.1-mini - cheaper fast default"
                "gpt-5-mini - compact next-gen option"
            )
            default_idx=1
            ;;
        anthropic)
            model_ids=("claude-sonnet-4-20250514" "claude-3-5-haiku-latest")
            model_options=(
                "claude-sonnet-4-20250514 - balanced reasoning"
                "claude-3-5-haiku-latest - fast and lower cost"
            )
            default_idx=0
            ;;
        openrouter)
            model_ids=("openai/gpt-4.1-mini" "anthropic/claude-3.5-haiku" "google/gemini-2.0-flash-001")
            model_options=(
                "openai/gpt-4.1-mini - interoperable default"
                "anthropic/claude-3.5-haiku - Anthropic via OpenRouter"
                "google/gemini-2.0-flash-001 - fast multimodal route"
            )
            default_idx=0
            ;;
        google)
            model_ids=("gemini-2.0-flash" "gemini-1.5-pro")
            model_options=(
                "gemini-2.0-flash - default fast API model"
                "gemini-1.5-pro - higher reasoning quality"
            )
            default_idx=0
            ;;
        custom)
            if [[ -n "${FLAG_MODEL:-}" ]]; then
                SELECTED_MODEL_ID="${FLAG_MODEL}"
                SELECTED_MODEL_NAME="${FLAG_MODEL}"
                export SELECTED_MODEL_ID SELECTED_MODEL_NAME
                log_success "Selected model: ${SELECTED_MODEL_ID}"
                return 0
            fi

            local custom_model_default="custom-model"
            if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
                if [[ -z "${FLAG_MODEL:-}" ]]; then
                    log_error "Custom provider requires --model when --defaults is used."
                    return 1
                fi
            fi

            SELECTED_MODEL_ID=$(prompt_input "Enter custom model ID" "${custom_model_default}")
            SELECTED_MODEL_NAME="${SELECTED_MODEL_ID}"
            export SELECTED_MODEL_ID SELECTED_MODEL_NAME
            log_success "Selected model: ${SELECTED_MODEL_ID}"
            return 0
            ;;
        *)
            model_ids=("qwen2.5:7b-instruct-q4_K_M")
            model_options=("qwen2.5:7b-instruct-q4_K_M - safe default")
            default_idx=0
            ;;
    esac

    local choice_label
    choice_label=$(prompt_choice "Choose default model" model_options "${default_idx}")

    local idx=0
    for idx in $(seq 0 $(( ${#model_options[@]} - 1 ))); do
        if [[ "${model_options[${idx}]}" == "${choice_label}" ]]; then
            SELECTED_MODEL_ID="${model_ids[${idx}]}"
            SELECTED_MODEL_NAME="${model_ids[${idx}]}"
            break
        fi
    done

    if [[ -z "${SELECTED_MODEL_ID:-}" ]]; then
        SELECTED_MODEL_ID="${model_ids[${default_idx}]}"
        SELECTED_MODEL_NAME="${model_ids[${default_idx}]}"
    fi

    export SELECTED_MODEL_ID SELECTED_MODEL_NAME
    log_success "Selected model: ${SELECTED_MODEL_ID}"
}

collect_provider_credentials_v2() {
    API_BASE_URL=""
    API_KEY=""
    CUSTOM_PROVIDER_NAME=""
    FALLBACK_PROVIDER=""
    FALLBACK_MODEL_ID=""

    case "${PRIMARY_PROVIDER}" in
        openai)
            API_KEY=$(prompt_secret "Enter OPENAI_API_KEY")
            API_BASE_URL=$(prompt_input "OpenAI base URL" "${FLAG_BASE_URL:-https://api.openai.com/v1}")
            ;;
        anthropic)
            API_KEY=$(prompt_secret "Enter ANTHROPIC_API_KEY")
            API_BASE_URL=$(prompt_input "Anthropic base URL" "${FLAG_BASE_URL:-https://api.anthropic.com}")
            ;;
        openrouter)
            API_KEY=$(prompt_secret "Enter OPENROUTER_API_KEY")
            API_BASE_URL=$(prompt_input "OpenRouter base URL" "${FLAG_BASE_URL:-https://openrouter.ai/api/v1}")
            ;;
        google)
            API_KEY=$(prompt_secret "Enter GOOGLE_API_KEY")
            API_BASE_URL=$(prompt_input "Google AI Studio base URL" "${FLAG_BASE_URL:-https://generativelanguage.googleapis.com/v1beta/openai}")
            ;;
        custom)
            CUSTOM_PROVIDER_NAME="${FLAG_PROVIDER_NAME:-}"
            if [[ -z "${CUSTOM_PROVIDER_NAME}" ]]; then
                if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
                    log_error "Custom provider requires --provider-name when --defaults is used."
                    return 1
                fi
                CUSTOM_PROVIDER_NAME=$(prompt_input "Custom provider label" "Custom AI")
            fi

            if [[ -n "${FLAG_API_KEY:-}" ]]; then
                API_KEY="${FLAG_API_KEY}"
            else
                API_KEY=$(prompt_secret "Enter custom provider API key")
            fi

            if [[ -z "${FLAG_BASE_URL:-}" ]]; then
                if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
                    log_error "Custom provider requires --base-url when --defaults is used."
                    return 1
                fi
                API_BASE_URL=$(prompt_input "Custom provider base URL" "https://your-provider.example.com/v1")
            else
                API_BASE_URL="${FLAG_BASE_URL}"
            fi
            ;;
        ollama)
            API_KEY="ollama"
            API_BASE_URL=$(prompt_input "Ollama base URL" "${FLAG_BASE_URL:-http://127.0.0.1:11434/v1}")
            ;;
    esac

    if [[ "${PRIMARY_PROVIDER}" != "ollama" && -n "${FLAG_API_KEY:-}" ]]; then
        API_KEY="${FLAG_API_KEY}"
    fi

    if [[ "${PRIMARY_PROVIDER}" != "ollama" && -z "${API_KEY}" ]]; then
        log_error "API key is required for provider ${PRIMARY_PROVIDER}."
        return 1
    fi

    if [[ -z "${API_BASE_URL}" ]]; then
        log_error "Base URL is required for provider ${PRIMARY_PROVIDER}."
        return 1
    fi

    if [[ "${RUNTIME_MODE}" == "hybrid" ]]; then
        if [[ "${PRIMARY_PROVIDER}" == "ollama" ]]; then
            FALLBACK_PROVIDER="openai"
            FALLBACK_MODEL_ID="gpt-4.1-mini"
        else
            FALLBACK_PROVIDER="ollama"
            FALLBACK_MODEL_ID="qwen2.5:7b-instruct-q4_K_M"
        fi
    fi

    export API_BASE_URL API_KEY CUSTOM_PROVIDER_NAME FALLBACK_PROVIDER FALLBACK_MODEL_ID
    log_info "Credential collection finished for ${PRIMARY_PROVIDER}"
}
