#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

JETPACK="${1:-}"
RELEASE="${2:-}"

if [[ -z "$JETPACK" ]]; then
    echo "Usage:"
    echo "  prepare.sh jp6"
    echo "  prepare.sh jp6 r36.4.4"
    exit 1
fi

if [[ -z "$RELEASE" ]]; then
    RELEASE="$(manifest_default_release "$JETPACK")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"

echo
echo "========================================"
echo " TegraForge Prepare"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo

#
# Extraction
#

if [[ ! -d "${BUILD_DIR}/Linux_for_Tegra" ]]; then

    echo "[INFO] BSP not extracted"
    echo "[INFO] Running extract.sh"
    echo

    "${ROOT}/scripts/extract.sh" \
        "${JETPACK}" \
        "${RELEASE}"
fi

L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

if [[ ! -d "${L4T_DIR}" ]]; then
    echo "[ERROR] Linux_for_Tegra not found"
    exit 1
fi

cd "${L4T_DIR}"

#
# Check rootfs
#

if [[ ! -d rootfs ]]; then
    echo "[ERROR] rootfs directory missing"
    exit 1
fi

if [[ ! -f apply_binaries.sh ]]; then
    echo "[ERROR] apply_binaries.sh missing"
    exit 1
fi

#
# Marker file
#

PREPARED_MARKER=".tegraforge_prepared"

if [[ -f "${PREPARED_MARKER}" ]]; then

    echo "[SKIP] BSP already prepared"
    echo

else

    echo "[RUN ] apply_binaries.sh"
    echo

    sudo ./apply_binaries.sh

    touch "${PREPARED_MARKER}"

    echo
    echo "[DONE] BSP prepared"
    echo

fi

echo "Location:"
echo "${L4T_DIR}"
echo