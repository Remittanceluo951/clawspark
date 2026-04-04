#!/usr/bin/env bash
set -euo pipefail

CLAWSPARK_V2_DIR="${HOME}/.clawspark-v2"
CLAWSPARK_V2_LOG="${CLAWSPARK_V2_DIR}/install.log"
CLAWSPARK_DEFAULTS="${CLAWSPARK_DEFAULTS:-false}"

if [[ -t 1 ]] && command -v tput &>/dev/null && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
fi

to_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

_ts() { date '+%H:%M:%S'; }

_log_to_file() {
    local level="$1"; shift
    mkdir -p "${CLAWSPARK_V2_DIR}"
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "$*" >> "${CLAWSPARK_V2_LOG}" 2>/dev/null || true
}

log_info() {
    printf '%s[%s]%s %s\n' "${BLUE}" "$(_ts)" "${RESET}" "$*"
    _log_to_file "INFO" "$*"
}

log_warn() {
    printf '%s[%s] WARNING:%s %s\n' "${YELLOW}" "$(_ts)" "${RESET}" "$*" >&2
    _log_to_file "WARN" "$*"
}

log_error() {
    printf '%s[%s] ERROR:%s %s\n' "${RED}" "$(_ts)" "${RESET}" "$*" >&2
    _log_to_file "ERROR" "$*"
}

log_success() {
    printf '%s[%s] OK:%s %s\n' "${GREEN}" "$(_ts)" "${RESET}" "$*"
    _log_to_file "OK" "$*"
}

check_command() {
    command -v "$1" &>/dev/null
}

prompt_choice() {
    local question="$1"
    local options_name="$2"
    local default_idx="${3:-0}"
    local count
    eval "count=\${#${options_name}[@]}"

    if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
        eval "printf '%s' \"\${${options_name}[${default_idx}]}\""
        return 0
    fi

    printf '\n%s%s%s\n' "${BOLD}" "${question}" "${RESET}" >/dev/tty
    local i opt marker
    for i in $(seq 0 $(( count - 1 ))); do
        marker=""
        if [[ "${i}" -eq "${default_idx}" ]]; then
            marker=" ${CYAN}(default)${RESET}"
        fi
        eval "opt=\${${options_name}[${i}]}"
        printf '  %s%d)%s %s%s\n' "${GREEN}" $(( i + 1 )) "${RESET}" "${opt}" "${marker}" >/dev/tty
    done

    local selection
    while true; do
        printf '%s> %s' "${BOLD}" "${RESET}" >/dev/tty
        read -r selection </dev/tty || selection=""
        if [[ -z "${selection}" ]]; then
            eval "printf '%s' \"\${${options_name}[${default_idx}]}\""
            return 0
        fi
        if [[ "${selection}" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= count )); then
            eval "printf '%s' \"\${${options_name}[$(( selection - 1 ))]}\""
            return 0
        fi
        printf '  %sPlease enter a number between 1 and %d%s\n' "${YELLOW}" "${count}" "${RESET}" >/dev/tty
    done
}

prompt_input() {
    local question="$1"
    local default_value="${2:-}"

    if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
        printf '%s' "${default_value}"
        return 0
    fi

    if [[ -n "${default_value}" ]]; then
        printf '\n%s%s%s [%s]: ' "${BOLD}" "${question}" "${RESET}" "${default_value}" >/dev/tty
    else
        printf '\n%s%s%s: ' "${BOLD}" "${question}" "${RESET}" >/dev/tty
    fi

    local value
    read -r value </dev/tty || value=""
    if [[ -z "${value}" ]]; then
        value="${default_value}"
    fi
    printf '%s' "${value}"
}

prompt_secret() {
    local question="$1"

    if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
        printf '%s' "${FLAG_API_KEY:-}"
        return 0
    fi

    printf '\n%s%s%s: ' "${BOLD}" "${question}" "${RESET}" >/dev/tty
    local value=""
    stty -echo </dev/tty
    read -r value </dev/tty || value=""
    stty echo </dev/tty
    printf '\n' >/dev/tty
    printf '%s' "${value}"
}

prompt_yn() {
    local question="$1"
    local default="${2:-y}"

    if [[ "${CLAWSPARK_DEFAULTS}" == "true" ]]; then
        [[ "${default}" == "y" ]] && return 0 || return 1
    fi

    local hint="[y/N]"
    [[ "${default}" == "y" ]] && hint="[Y/n]"
    printf '\n%s%s %s%s ' "${BOLD}" "${question}" "${hint}" "${RESET}" >/dev/tty

    local answer
    read -r answer </dev/tty || answer=""
    answer=$(to_lower "${answer}")
    if [[ -z "${answer}" ]]; then
        [[ "${default}" == "y" ]] && return 0 || return 1
    fi
    [[ "${answer}" =~ ^y(es)?$ ]]
}

spinner() {
    local pid="$1"
    local msg="${2:-Working...}"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local frame_count=${#frames[@]}
    local i=0

    if [[ ! -t 1 ]]; then
        wait "${pid}" 2>/dev/null || true
        return 0
    fi

    printf '  '
    while kill -0 "${pid}" 2>/dev/null; do
        printf '\r  %s%s%s %s' "${CYAN}" "${frames[i % frame_count]}" "${RESET}" "${msg}"
        i=$(( i + 1 ))
        sleep 0.08
    done

    wait "${pid}" 2>/dev/null
    local exit_code=$?
    if [[ ${exit_code} -eq 0 ]]; then
        printf '\r  %s✓%s %s\n' "${GREEN}" "${RESET}" "${msg}"
    else
        printf '\r  %s✗%s %s\n' "${RED}" "${RESET}" "${msg}"
    fi
    return 0
}

hr() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 60)
    printf '%s%*s%s\n' "${BLUE}" "${cols}" '' "${RESET}" | tr ' ' '─'
}

mask_value() {
    local value="$1"
    if [[ -z "${value}" ]]; then
        printf '(empty)'
    elif [[ ${#value} -le 8 ]]; then
        printf '********'
    else
        printf '%s****%s' "${value:0:4}" "${value: -4}"
    fi
}

write_key_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    touch "${file}"
    if grep -q "^${key}=" "${file}" 2>/dev/null; then
        python3 - "$file" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
with open(path, 'w', encoding='utf-8') as fh:
    for line in lines:
        if line.startswith(f"{key}="):
            fh.write(f"{key}={value}\n")
        else:
            fh.write(line)
PY
    else
        printf '%s=%s\n' "${key}" "${value}" >> "${file}"
    fi
}
