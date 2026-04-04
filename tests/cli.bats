#!/usr/bin/env bats
# cli.bats -- Tests for CLI command routing and top-level behavior.

load test_helper

CLAWSPARK_BIN="${PROJECT_ROOT}/clawspark"

# ── Version ───────────────────────────────────────────────────────────────────

@test "--version outputs version string" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' --version"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^clawspark\ v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "-v outputs version string" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' -v"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^clawspark\ v ]]
}

@test "version command outputs version string" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"clawspark v"* ]]
}

# ── Help ──────────────────────────────────────────────────────────────────────

@test "--help outputs usage information" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' --help"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Commands:"* ]]
}

@test "help command outputs usage information" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' help"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "-h outputs usage information" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' -h"
    [ "$status" -eq 0 ]
    [[ "$output" == *"clawspark"* ]]
}

@test "no arguments shows help" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "help lists status command" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' help"
    [[ "$output" == *"status"* ]]
}

@test "help lists skills command" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' help"
    [[ "$output" == *"skills"* ]]
}

@test "help lists model command" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' help"
    [[ "$output" == *"model"* ]]
}

# ── Unknown command ───────────────────────────────────────────────────────────

@test "unknown command exits with error" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' __nonexistent_cmd__" 2>&1
    [ "$status" -eq 1 ]
}

@test "unknown command shows error message" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' __nonexistent_cmd__ 2>&1"
    [[ "$output" == *"Unknown command"* ]]
}

@test "unknown command still shows usage" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' __nonexistent_cmd__ 2>&1"
    [[ "$output" == *"Usage:"* ]]
}

# ── Command routing ──────────────────────────────────────────────────────────

@test "skills subcommand with no args exits with error" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' skills 2>&1"
    [ "$status" -eq 1 ]
}

@test "skills add without name exits with error" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' skills add 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* || "$output" == *"usage"* || "$output" == *"clawspark skills add"* ]]
}

@test "skills remove without name exits with error" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' skills remove 2>&1"
    [ "$status" -eq 1 ]
}

@test "model subcommand unknown exits with error" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' model bogus 2>&1"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown model subcommand"* ]]
}

# ── Version constant ─────────────────────────────────────────────────────────

@test "CLAWSPARK_VERSION is defined in the script" {
    run bash -c "grep -q 'CLAWSPARK_VERSION=' '${CLAWSPARK_BIN}'"
    [ "$status" -eq 0 ]
}

@test "version format is semver" {
    run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DIR='${CLAWSPARK_DIR}'; bash '${CLAWSPARK_BIN}' --version"
    [[ "$output" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]
}

# ── v2 custom provider ───────────────────────────────────────────────────────

@test "status shows custom provider and remote endpoint health" {
        mkdir -p "${HOME}/.openclaw" "${TEST_TEMP_DIR}/bin"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=custom
CUSTOM_AI_PROVIDER_NAME=My Gateway
CUSTOM_AI_BASE_URL=https://llm.example.com/v1
ENV

        cat > "${TEST_TEMP_DIR}/bin/curl" <<'SH'
#!/usr/bin/env bash
printf '401'
SH
        chmod +x "${TEST_TEMP_DIR}/bin/curl"

        run bash -c "export HOME='${TEST_TEMP_DIR}'; export PATH='${TEST_TEMP_DIR}/bin:'\"\$PATH\"; bash '${CLAWSPARK_BIN}' status"
        [ "$status" -eq 0 ]
        [[ "$output" == *"custom (My Gateway)"* ]]
        [[ "$output" == *"Remote endpoint"* ]]
        [[ "$output" == *"responding (HTTP 401)"* ]]
        [[ "$output" == *"https://llm.example.com/v1"* ]]
}

@test "model list shows remote provider details for custom v2 profile" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=custom
CUSTOM_AI_PROVIDER_NAME=My Gateway
CUSTOM_AI_BASE_URL=https://llm.example.com/v1
ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/my-model",
            "imageModel": "openai/my-vision-model"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "custom",
        "customProviderName": "My Gateway"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_SKIP_REMOTE_HEALTHCHECK='true'; bash '${CLAWSPARK_BIN}' model list"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Primary (chat)     :"* ]]
        [[ "$output" == *"openai/my-model"* ]]
        [[ "$output" == *"Remote/API Provider:"* ]]
        [[ "$output" == *"custom (My Gateway)"* ]]
        [[ "$output" == *"https://llm.example.com/v1"* ]]
}

@test "provider show reports current custom provider configuration" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=custom
CUSTOM_AI_PROVIDER_NAME=My Gateway
CUSTOM_AI_BASE_URL=https://llm.example.com/v1
CUSTOM_AI_API_KEY=secret-token
ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/my-model"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "custom",
        "customProviderName": "My Gateway"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider"* ]]
        [[ "$output" == *"custom (My Gateway)"* ]]
        [[ "$output" == *"https://llm.example.com/v1"* ]]
        [[ "$output" == *"configured via CUSTOM_AI_API_KEY"* ]]
}

@test "provider list shows catalog and active provider marker" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=openai
OPENAI_BASE_URL=https://api.openai.com/v1
ENV

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider list"
        [ "$status" -eq 0 ]
        [[ "$output" == *"provider catalog"* ]]
        [[ "$output" == *"* openai"* ]]
        [[ "$output" == *"custom"* ]]
        [[ "$output" == *"https://api.openai.com/v1"* ]]
        [[ "$output" == *"https://your-provider.example.com/v1"* ]]
}

    @test "provider doctor succeeds for healthy custom provider config" {
        mkdir -p "${HOME}/.openclaw" "${TEST_TEMP_DIR}/bin"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
    CLAWSPARK_V2_RUNTIME_MODE=api-only
    CLAWSPARK_V2_PRIMARY_PROVIDER=custom
    CUSTOM_AI_PROVIDER_NAME=My Gateway
    CUSTOM_AI_BASE_URL=https://llm.example.com/v1
    CUSTOM_AI_API_KEY=secret-token
    ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
    {
        "agents": {
        "defaults": {
            "model": "openai/my-model"
        }
        },
        "clawsparkV2": {
        "primaryProvider": "custom",
        "customProviderName": "My Gateway"
        }
    }
    JSON

        cat > "${TEST_TEMP_DIR}/bin/curl" <<'SH'
    #!/usr/bin/env bash
    printf '401'
    SH
        chmod +x "${TEST_TEMP_DIR}/bin/curl"

        run bash -c "export HOME='${TEST_TEMP_DIR}'; export PATH='${TEST_TEMP_DIR}/bin:'\"\$PATH\"; bash '${CLAWSPARK_BIN}' provider doctor"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider diagnostics passed"* ]]
        [[ "$output" == *"responding (HTTP 401)"* ]]
    }

    @test "provider doctor fails for missing remote api key" {
        mkdir -p "${HOME}/.openclaw" "${TEST_TEMP_DIR}/bin"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
    CLAWSPARK_V2_RUNTIME_MODE=api-only
    CLAWSPARK_V2_PRIMARY_PROVIDER=openai
    OPENAI_BASE_URL=https://api.openai.com/v1
    ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
    {
        "agents": {
        "defaults": {
            "model": "openai/gpt-4.1-mini"
        }
        },
        "clawsparkV2": {
        "primaryProvider": "openai"
        }
    }
    JSON

        cat > "${TEST_TEMP_DIR}/bin/curl" <<'SH'
    #!/usr/bin/env bash
    printf '401'
    SH
        chmod +x "${TEST_TEMP_DIR}/bin/curl"

        run bash -c "export HOME='${TEST_TEMP_DIR}'; export PATH='${TEST_TEMP_DIR}/bin:'\"\$PATH\"; bash '${CLAWSPARK_BIN}' provider doctor"
        [ "$status" -eq 1 ]
        [[ "$output" == *"API key is missing (OPENAI_API_KEY)"* ]]
        [[ "$output" == *"Provider diagnostics found issues"* ]]
    }

@test "provider set-custom updates gateway env and openclaw config" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=openai
OPENAI_BASE_URL=https://api.openai.com/v1
ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/gpt-4.1-mini"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "openai"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider set-custom --name 'Acme AI' --base-url 'https://api.acme.ai/v1' --api-key 'abc123'"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Custom provider updated: Acme AI"* ]]

        run bash -c "grep -q '^CLAWSPARK_V2_PRIMARY_PROVIDER=custom$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^CUSTOM_AI_PROVIDER_NAME=Acme AI$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^CUSTOM_AI_BASE_URL=https://api.acme.ai/v1$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^CUSTOM_AI_API_KEY=abc123$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "python3 -c \"import json; cfg=json.load(open('${HOME}/.openclaw/openclaw.json', 'r', encoding='utf-8')); assert cfg['clawsparkV2']['primaryProvider'] == 'custom'; assert cfg['clawsparkV2']['customProviderName'] == 'Acme AI'\""
        [ "$status" -eq 0 ]
}

@test "provider set openai updates gateway env and provider metadata" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/gateway.env" <<'ENV'
CLAWSPARK_V2_RUNTIME_MODE=api-only
CLAWSPARK_V2_PRIMARY_PROVIDER=custom
CUSTOM_AI_PROVIDER_NAME=Legacy Gateway
CUSTOM_AI_BASE_URL=https://legacy.example.com/v1
ENV

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/gpt-4.1-mini"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "custom",
        "customProviderName": "Legacy Gateway"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider set openai --base-url 'https://api.openai.com/v1' --api-key 'sk-openai'"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider updated: openai"* ]]

        run bash -c "grep -q '^CLAWSPARK_V2_PRIMARY_PROVIDER=openai$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OPENAI_BASE_URL=https://api.openai.com/v1$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OPENAI_API_KEY=sk-openai$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "python3 -c \"import json; cfg=json.load(open('${HOME}/.openclaw/openclaw.json', 'r', encoding='utf-8')); assert cfg['clawsparkV2']['primaryProvider'] == 'openai'; assert 'customProviderName' not in cfg['clawsparkV2']\""
        [ "$status" -eq 0 ]
}

@test "provider use openrouter applies default base url" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/gpt-4.1-mini"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "openai"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider use openrouter"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider updated: openrouter"* ]]
        [[ "$output" == *"No API key was provided"* ]]

        run bash -c "grep -q '^CLAWSPARK_V2_PRIMARY_PROVIDER=openrouter$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OPENROUTER_BASE_URL=https://openrouter.ai/api/v1$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
}

@test "provider use ollama applies local default base url" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "ollama/qwen2.5:7b"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "openai"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; bash '${CLAWSPARK_BIN}' provider use ollama"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider updated: ollama"* ]]

        run bash -c "grep -q '^CLAWSPARK_V2_PRIMARY_PROVIDER=ollama$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OLLAMA_BASE_URL=http://127.0.0.1:11434/v1$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OLLAMA_API_KEY=ollama$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
}

@test "provider use without args uses current provider in defaults mode" {
        mkdir -p "${HOME}/.openclaw"

        cat > "${HOME}/.openclaw/openclaw.json" <<'JSON'
{
    "agents": {
        "defaults": {
            "model": "openai/gpt-4.1-mini"
        }
    },
    "clawsparkV2": {
        "primaryProvider": "openai"
    }
}
JSON

        run bash -c "export HOME='${TEST_TEMP_DIR}'; export CLAWSPARK_DEFAULTS='true'; bash '${CLAWSPARK_BIN}' provider use"
        [ "$status" -eq 0 ]
        [[ "$output" == *"Provider updated: openai"* ]]

        run bash -c "grep -q '^CLAWSPARK_V2_PRIMARY_PROVIDER=openai$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
        run bash -c "grep -q '^OPENAI_BASE_URL=https://api.openai.com/v1$' '${HOME}/.openclaw/gateway.env'"
        [ "$status" -eq 0 ]
}
