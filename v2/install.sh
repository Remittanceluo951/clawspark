#!/usr/bin/env bash
# License: non-commercial use only. Individuals and organizations may use
# this software only for strictly non-commercial purposes. Commercialization,
# third-party consulting, client work, and other commercial use are
# prohibited without prior written permission from Nguyen Thanh An by Pho Tue
# SoftWare Solutions JSC. See ../LICENSE and ../NOTICE.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLAWSPARK_DEFAULTS="${CLAWSPARK_DEFAULTS:-false}"
FLAG_RUNTIME_MODE=""
FLAG_PROVIDER=""
FLAG_API_KEY=""
FLAG_BASE_URL=""
FLAG_PROVIDER_NAME=""
FLAG_MODEL=""
FLAG_MESSAGING=""
AIR_GAP="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --defaults)
            CLAWSPARK_DEFAULTS="true"
            shift ;;
        --runtime=*)
            FLAG_RUNTIME_MODE="${1#*=}"
            shift ;;
        --provider=*)
            FLAG_PROVIDER="${1#*=}"
            shift ;;
        --api-key=*)
            FLAG_API_KEY="${1#*=}"
            shift ;;
        --base-url=*)
            FLAG_BASE_URL="${1#*=}"
            shift ;;
        --provider-name=*)
            FLAG_PROVIDER_NAME="${1#*=}"
            shift ;;
        --model=*)
            FLAG_MODEL="${1#*=}"
            shift ;;
        --messaging=*)
            FLAG_MESSAGING="${1#*=}"
            shift ;;
        --air-gap|--airgap)
            AIR_GAP="true"
            shift ;;
        -h|--help)
            cat <<HELP
Usage: v2/install.sh [OPTIONS]

Options:
  --defaults              Skip interactive prompts
  --runtime=<mode>        local-gpu | local-cpu | api-only | hybrid
    --provider=<name>       ollama | openai | anthropic | openrouter | google | custom
  --api-key=<key>         Provider API key for API modes
    --base-url=<url>        Override provider API base URL
    --provider-name=<name>  Label for custom API provider
  --model=<id>            Override default model ID
    --messaging=<type>      whatsapp | telegram | both | skip
    --air-gap               Enable outbound network lock-down after setup
  -h, --help              Show this help
HELP
            exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1 ;;
    esac
done

CLAWSPARK_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export CLAWSPARK_DEFAULTS FLAG_RUNTIME_MODE FLAG_PROVIDER FLAG_API_KEY FLAG_BASE_URL FLAG_PROVIDER_NAME FLAG_MODEL
export FLAG_MESSAGING AIR_GAP CLAWSPARK_REPO_DIR

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/detect-hardware.sh"
source "${SCRIPT_DIR}/lib/select-runtime.sh"
source "${SCRIPT_DIR}/lib/setup-provider.sh"
source "${SCRIPT_DIR}/lib/setup-openclaw.sh"
source "${SCRIPT_DIR}/lib/setup-extras.sh"
source "${SCRIPT_DIR}/lib/verify.sh"

mkdir -p "${CLAWSPARK_V2_DIR}"
: > "${CLAWSPARK_V2_LOG}"

show_banner_v2() {
    printf '\n%s%sclawspark v2%s\n' "${BOLD}" "${BLUE}" "${RESET}"
    printf '%sCPU-ready, API-ready OpenClaw installer%s\n\n' "${CYAN}" "${RESET}"
    hr
}

show_banner_v2

detect_hardware_v2
select_runtime_v2
select_provider_v2
select_model_v2

if [[ -n "${FLAG_MODEL}" ]]; then
    SELECTED_MODEL_ID="${FLAG_MODEL}"
    SELECTED_MODEL_NAME="${FLAG_MODEL}"
fi

collect_provider_credentials_v2
setup_provider_v2
setup_openclaw_v2
setup_v2_extras
verify_v2_installation

printf '\n'
log_success "clawspark v2 setup finished."
print_box \
    "${BOLD}Summary${RESET}" \
    "" \
    "Runtime   : ${RUNTIME_MODE}" \
    "Provider  : ${PRIMARY_PROVIDER}" \
    "Model     : ${SELECTED_MODEL_ID}" \
    "API URL   : ${INFERENCE_API_URL:-n/a}"
