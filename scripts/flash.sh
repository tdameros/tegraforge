#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

FLASH_ARGS="${1:-}"
JETPACK="${2:-}"
RELEASE="${3:-}"

if [[ -z "$JETPACK" ]]; then
    echo "Usage:"
    echo "  flash.sh "jetson-agx-orin-devkit mmcblk0p1" jp6"
    echo "  flash.sh "jetson-agx-orin-devkit mmcblk0p1" jp6 r36.4.4"
    exit 1
fi

if [[ -z "$RELEASE" ]]; then
    RELEASE="$(manifest_default_release "$JETPACK")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"

echo
echo "========================================"
echo " TegraForge Flash"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo

L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

if [[ ! -d "${L4T_DIR}" ]]; then
    echo "[ERROR] Linux_for_Tegra not found"
    exit 1
fi

cd "${L4T_DIR}"

eval "sudo ./flash.sh ${FLASH_ARGS}"

echo "[DONE] Flash applied"