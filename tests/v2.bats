#!/usr/bin/env bats
# v2.bats -- Tests for v2 installer selection and custom provider flow.

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="${TEST_TEMP_DIR}"
    export CLAWSPARK_DIR="${TEST_TEMP_DIR}/.clawspark-v2"
    export CLAWSPARK_LOG="${CLAWSPARK_DIR}/install.log"
    mkdir -p "${CLAWSPARK_DIR}"
}

teardown() {
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "${TEST_TEMP_DIR}" ]]; then
        rm -rf "${TEST_TEMP_DIR}"
    fi
}

@test "v2 help lists custom provider flags" {
    run bash "${PROJECT_ROOT}/v2/install.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"custom"* ]]
    [[ "$output" == *"--base-url=<url>"* ]]
    [[ "$output" == *"--provider-name=<name>"* ]]
}

@test "select_provider_v2 accepts custom provider in api-only mode" {
    run bash -c "
        export HOME='${TEST_TEMP_DIR}'
        export CLAWSPARK_DIR='${TEST_TEMP_DIR}/.clawspark-v2'
        export CLAWSPARK_LOG='${TEST_TEMP_DIR}/.clawspark-v2/install.log'
        export CLAWSPARK_DEFAULTS='true'
        export HW_ACCELERATION='cpu'
        export RUNTIME_MODE='api-only'
        export FLAG_PROVIDER='custom'
        source '${PROJECT_ROOT}/v2/lib/common.sh'
        source '${PROJECT_ROOT}/v2/lib/select-runtime.sh'
        select_provider_v2 >/dev/null
        printf '%s' \"\${PRIMARY_PROVIDER}\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "custom" ]
}

@test "select_model_v2 uses explicit custom model flag" {
    run bash -c "
        export HOME='${TEST_TEMP_DIR}'
        export CLAWSPARK_DIR='${TEST_TEMP_DIR}/.clawspark-v2'
        export CLAWSPARK_LOG='${TEST_TEMP_DIR}/.clawspark-v2/install.log'
        export CLAWSPARK_DEFAULTS='true'
        export PRIMARY_PROVIDER='custom'
        export FLAG_MODEL='my-custom-model'
        source '${PROJECT_ROOT}/v2/lib/common.sh'
        source '${PROJECT_ROOT}/v2/lib/select-runtime.sh'
        select_model_v2 >/dev/null
        printf '%s|%s' \"\${SELECTED_MODEL_ID}\" \"\${SELECTED_MODEL_NAME}\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "my-custom-model|my-custom-model" ]
}

@test "collect_provider_credentials_v2 rejects missing custom provider name in defaults mode" {
    run bash -c "
        export HOME='${TEST_TEMP_DIR}'
        export CLAWSPARK_DIR='${TEST_TEMP_DIR}/.clawspark-v2'
        export CLAWSPARK_LOG='${TEST_TEMP_DIR}/.clawspark-v2/install.log'
        export CLAWSPARK_DEFAULTS='true'
        export PRIMARY_PROVIDER='custom'
        export FLAG_API_KEY='sk-test'
        export FLAG_BASE_URL='https://llm.example.com/v1'
        source '${PROJECT_ROOT}/v2/lib/common.sh'
        source '${PROJECT_ROOT}/v2/lib/select-runtime.sh'
        collect_provider_credentials_v2
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"requires --provider-name"* ]]
}

@test "collect_provider_credentials_v2 populates custom provider fields from flags" {
    run bash -c "
        export HOME='${TEST_TEMP_DIR}'
        export CLAWSPARK_DIR='${TEST_TEMP_DIR}/.clawspark-v2'
        export CLAWSPARK_LOG='${TEST_TEMP_DIR}/.clawspark-v2/install.log'
        export CLAWSPARK_DEFAULTS='true'
        export PRIMARY_PROVIDER='custom'
        export RUNTIME_MODE='api-only'
        export FLAG_API_KEY='sk-test'
        export FLAG_BASE_URL='https://llm.example.com/v1'
        export FLAG_PROVIDER_NAME='My Gateway'
        source '${PROJECT_ROOT}/v2/lib/common.sh'
        source '${PROJECT_ROOT}/v2/lib/select-runtime.sh'
        collect_provider_credentials_v2 >/dev/null
        printf '%s|%s|%s' \"\${API_KEY}\" \"\${API_BASE_URL}\" \"\${CUSTOM_PROVIDER_NAME}\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "sk-test|https://llm.example.com/v1|My Gateway" ]
}

@test "collect_provider_credentials_v2 sets ollama fallback for custom hybrid mode" {
    run bash -c "
        export HOME='${TEST_TEMP_DIR}'
        export CLAWSPARK_DIR='${TEST_TEMP_DIR}/.clawspark-v2'
        export CLAWSPARK_LOG='${TEST_TEMP_DIR}/.clawspark-v2/install.log'
        export CLAWSPARK_DEFAULTS='true'
        export PRIMARY_PROVIDER='custom'
        export RUNTIME_MODE='hybrid'
        export FLAG_API_KEY='sk-test'
        export FLAG_BASE_URL='https://llm.example.com/v1'
        export FLAG_PROVIDER_NAME='My Gateway'
        source '${PROJECT_ROOT}/v2/lib/common.sh'
        source '${PROJECT_ROOT}/v2/lib/select-runtime.sh'
        collect_provider_credentials_v2 >/dev/null
        printf '%s|%s' \"\${FALLBACK_PROVIDER}\" \"\${FALLBACK_MODEL_ID}\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "ollama|qwen2.5:7b-instruct-q4_K_M" ]
}