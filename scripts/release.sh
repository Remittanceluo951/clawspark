#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

usage() {
    cat <<'USAGE'
Usage: bash scripts/release.sh [patch|minor|major|<version>] [--push]

Examples:
  bash scripts/release.sh patch
  bash scripts/release.sh minor --push
  bash scripts/release.sh 2.1.0 --push
USAGE
}

require_clean_git() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Working tree is not clean. Commit or stash changes before releasing." >&2
        exit 1
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Required command not found: $1" >&2
        exit 1
    }
}

resolve_command() {
    local candidate="$1"
    local resolved=""

    if resolved="$(command -v "${candidate}" 2>/dev/null)" && [[ -n "${resolved}" ]]; then
        printf '%s' "${resolved}"
        return 0
    fi

    if resolved="$(command -v "${candidate}.exe" 2>/dev/null)" && [[ -n "${resolved}" ]]; then
        printf '%s' "${resolved}"
        return 0
    fi

    if resolved="$(command -v "${candidate}.cmd" 2>/dev/null)" && [[ -n "${resolved}" ]]; then
        printf '%s' "${resolved}"
        return 0
    fi

    if command -v where.exe >/dev/null 2>&1; then
        resolved="$(where.exe "${candidate}" 2>/dev/null | head -n 1 | tr -d '\r')"
        if [[ -n "${resolved}" ]]; then
            printf '%s' "${resolved}"
            return 0
        fi
    fi

    return 1
}

require_runtime_command() {
    local candidate="$1"
    local resolved=""

    if resolved="$(resolve_command "${candidate}" 2>/dev/null)" && [[ -n "${resolved}" ]]; then
        printf '%s' "${resolved}"
        return 0
    fi

    echo "Required command not found: ${candidate}" >&2
    exit 1
}

bump_arg="${1:-}"
push_flag="false"

if [[ -z "${bump_arg}" || "${bump_arg}" == "-h" || "${bump_arg}" == "--help" ]]; then
    usage
    exit 0
fi

shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --push)
            push_flag="true"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

require_command git
require_command bash

NODE_BIN="$(require_runtime_command node)"
NPM_BIN="$(require_runtime_command npm)"

require_clean_git

bash -n ./clawspark
bash ./tests/run.sh
"${NPM_BIN}" pack --dry-run >/dev/null

case "${bump_arg}" in
    patch|minor|major)
        "${NPM_BIN}" version "${bump_arg}"
        ;;
    *)
        if [[ ! "${bump_arg}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Version must be patch, minor, major, or an explicit semver like 2.1.0" >&2
            exit 1
        fi
        "${NPM_BIN}" version "${bump_arg}"
        ;;
esac

new_version="$("${NODE_BIN}" -p "require('./package.json').version")"
echo "Prepared release v${new_version}"

echo "Next steps:"
echo "  git push origin main --follow-tags"

echo "This will trigger CI, npm publish, and GitHub Release workflows once pushed."

if [[ "${push_flag}" == "true" ]]; then
    git push origin main --follow-tags
fi
