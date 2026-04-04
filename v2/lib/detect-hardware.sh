#!/usr/bin/env bash
set -euo pipefail

detect_hardware_v2() {
    log_info "Detecting hardware profile for v2..."

    HW_CPU_ARCH=$(uname -m)
    if [[ -f /proc/cpuinfo ]]; then
        HW_CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
    elif check_command sysctl; then
        HW_CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    else
        HW_CPU_CORES=1
    fi

    if [[ -f /proc/meminfo ]]; then
        local mem_kb
        mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
        HW_TOTAL_RAM_MB=$(( mem_kb / 1024 ))
    elif check_command sysctl; then
        local mem_bytes
        mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
        HW_TOTAL_RAM_MB=$(( mem_bytes / 1024 / 1024 ))
    else
        HW_TOTAL_RAM_MB=0
    fi

    HW_GPU_NAME="none"
    HW_GPU_VRAM_MB=0
    HW_DRIVER_VERSION="n/a"
    HW_ACCELERATION="cpu"
    HW_PLATFORM="cpu-generic"

    if [[ -f /etc/nv_tegra_release ]] || uname -r 2>/dev/null | grep -qi tegra; then
        HW_PLATFORM="jetson"
        HW_GPU_NAME="NVIDIA Jetson (Tegra)"
        HW_GPU_VRAM_MB="${HW_TOTAL_RAM_MB}"
        HW_ACCELERATION="gpu"
    fi

    if [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
        local product_name
        product_name=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "")
        if echo "${product_name}" | grep -qiE "DGX.Spark|DGX_Spark"; then
            HW_PLATFORM="dgx-spark"
            HW_GPU_NAME="NVIDIA GB10 / DGX Spark"
            HW_GPU_VRAM_MB=131072
            HW_TOTAL_RAM_MB=131072
            HW_ACCELERATION="gpu"
        fi
    fi

    if check_command nvidia-smi; then
        local gpu_info
        gpu_info=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits 2>/dev/null || echo "")
        if [[ -n "${gpu_info}" ]]; then
            local first_gpu
            first_gpu=$(echo "${gpu_info}" | head -n1)
            HW_GPU_NAME=$(echo "${first_gpu}" | cut -d',' -f1 | xargs)
            local vram_str
            vram_str=$(echo "${first_gpu}" | cut -d',' -f2 | xargs)
            if [[ "${vram_str}" =~ ^[0-9]+ ]]; then
                HW_GPU_VRAM_MB="${vram_str%%.*}"
            fi
            HW_DRIVER_VERSION=$(echo "${first_gpu}" | cut -d',' -f3 | xargs)
            HW_ACCELERATION="gpu"
            if [[ "${HW_PLATFORM}" == "cpu-generic" ]]; then
                if echo "${HW_GPU_NAME}" | grep -qiE "RTX|GeForce|Quadro"; then
                    HW_PLATFORM="rtx"
                else
                    HW_PLATFORM="gpu-generic"
                fi
            fi
        fi
    fi

    if [[ "${HW_PLATFORM}" == "cpu-generic" && "$(uname)" == "Darwin" ]]; then
        local chip_info
        chip_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "")
        if echo "${chip_info}" | grep -qi "Apple"; then
            HW_PLATFORM="mac"
            HW_GPU_NAME="Apple Silicon (${chip_info})"
            HW_GPU_VRAM_MB="${HW_TOTAL_RAM_MB}"
            HW_DRIVER_VERSION="Metal"
            HW_ACCELERATION="gpu"
        fi
    fi

    if [[ "${HW_ACCELERATION}" == "cpu" ]]; then
        if (( HW_TOTAL_RAM_MB >= 32768 )); then
            HW_CPU_PROFILE="cpu-large"
        elif (( HW_TOTAL_RAM_MB >= 16384 )); then
            HW_CPU_PROFILE="cpu-medium"
        else
            HW_CPU_PROFILE="cpu-small"
        fi
    else
        HW_CPU_PROFILE="with-gpu"
    fi

    export HW_CPU_ARCH HW_CPU_CORES HW_TOTAL_RAM_MB HW_GPU_NAME HW_GPU_VRAM_MB
    export HW_DRIVER_VERSION HW_ACCELERATION HW_PLATFORM HW_CPU_PROFILE

    local ram_gb=$(( HW_TOTAL_RAM_MB / 1024 ))
    local vram_gb=$(( HW_GPU_VRAM_MB / 1024 ))
    print_box \
        "${BOLD}v2 Hardware Summary${RESET}" \
        "" \
        "Platform      : ${CYAN}${HW_PLATFORM}${RESET}" \
        "Acceleration  : ${HW_ACCELERATION}" \
        "GPU           : ${HW_GPU_NAME}" \
        "VRAM          : ${vram_gb} GB" \
        "System RAM    : ${ram_gb} GB" \
        "CPU Cores     : ${HW_CPU_CORES} (${HW_CPU_ARCH})" \
        "CPU Profile   : ${HW_CPU_PROFILE}" \
        "Driver        : ${HW_DRIVER_VERSION}"

    log_success "Hardware profile ready: ${HW_PLATFORM} / ${HW_ACCELERATION}"
}
