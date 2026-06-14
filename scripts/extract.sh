#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

JETPACK="${1:-}"
RELEASE="${2:-}"

if [[ -z "$JETPACK" ]]; then
    echo "Usage:"
    echo "  extract.sh jp6"
    echo "  extract.sh jp6 r36.4.4"
    exit 1
fi

if [[ -z "$RELEASE" ]]; then
    RELEASE="$(manifest_default_release "$JETPACK")"
fi

DOWNLOAD_DIR="${ROOT}/downloads/${JETPACK}/${RELEASE}"
BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"

mkdir -p "${BUILD_DIR}"

echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo

#
# Resolve archive names from manifest
#

BSP_FILE="$(manifest_file_name "$JETPACK" "$RELEASE" bsp)"
ROOTFS_FILE="$(manifest_file_name "$JETPACK" "$RELEASE" rootfs)"
SOURCES_FILE="$(manifest_file_name "$JETPACK" "$RELEASE" sources)"

BSP_ARCHIVE="${DOWNLOAD_DIR}/bsp/${BSP_FILE}"
ROOTFS_ARCHIVE="${DOWNLOAD_DIR}/rootfs/${ROOTFS_FILE}"
SOURCES_ARCHIVE="${DOWNLOAD_DIR}/sources/${SOURCES_FILE}"

#
# Sanity checks
#

[[ -f "$BSP_ARCHIVE" ]] || {
    echo "Missing BSP archive"
    echo "$BSP_ARCHIVE"
    exit 1
}

[[ -f "$ROOTFS_ARCHIVE" ]] || {
    echo "Missing RootFS archive"
    echo "$ROOTFS_ARCHIVE"
    exit 1
}

[[ -f "$SOURCES_ARCHIVE" ]] || {
    echo "Missing Sources archive"
    echo "$SOURCES_ARCHIVE"
    exit 1
}

#
# Extract BSP
#

if [[ ! -d "${BUILD_DIR}/Linux_for_Tegra" ]]; then

    echo "[EXTRACT] BSP"

    tar -xjf \
        "$BSP_ARCHIVE" \
        -C "$BUILD_DIR"

else

    echo "[SKIP] Linux_for_Tegra already extracted"

fi

#
# Extract RootFS
#

ROOTFS_DIR="${BUILD_DIR}/Linux_for_Tegra/rootfs"

mkdir -p "$ROOTFS_DIR"

if [[ ! -f "${ROOTFS_DIR}/etc/os-release" ]]; then

    echo "[EXTRACT] RootFS"

    sudo tar \
        -xpf "$ROOTFS_ARCHIVE" \
        -C "$ROOTFS_DIR"

else

    echo "[SKIP] RootFS already extracted"

fi

#
# Extract Sources
#

if [[ ! -d "${BUILD_DIR}/sources" ]]; then

    echo "[EXTRACT] Sources"

    mkdir -p "${BUILD_DIR}/sources"

    tar -xjf \
        "$SOURCES_ARCHIVE" \
        -C "${BUILD_DIR}/sources"

else

    echo "[SKIP] Sources already extracted"

fi

echo
echo "[DONE]"
echo

echo "Build tree:"
echo

echo "${BUILD_DIR}"