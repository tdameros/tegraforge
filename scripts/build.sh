#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

FORCE=false
while getopts "f" opt; do
    case "${opt}" in
        f) FORCE=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

JETPACK="${1:-}"
RELEASE="${2:-}"

usage()
{
    echo "Usage:"
    echo "  build.sh jp5"
    echo "  build.sh jp5 35.6.4"
    echo ""
    echo "Options:"
    echo "  -f  Force rebuild even if already built"
    exit 1
}

if [[ -z "${JETPACK}" ]]; then
    usage
fi

if [[ -z "${RELEASE}" ]]; then
    RELEASE="$(manifest_default_release "${JETPACK}")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"
L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"
TOOLCHAIN_DIR="${BUILD_DIR}/toolchain"
KERNEL_OUT="${BUILD_DIR}/kernel_out"
MODULES_OUT="${BUILD_DIR}/modules_out"
MARKER="${BUILD_DIR}/.tegraforge_build"

echo
echo "========================================"
echo " TegraForge Build"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo

#
# Idempotency
#

if [[ -f "${MARKER}" ]]; then
    if [[ "${FORCE}" == true ]]; then
        echo "[FORCE] Re-building (removing marker)"
        rm -f "${MARKER}"
    else
        echo "[SKIP] Already built (use -f to force)"
        exit 0
    fi
fi

#
# Detect kernel source tree
#

echo "[DETECT] Kernel source"

KERNEL_SRC="$(find "${L4T_DIR}/sources" -maxdepth 6 -path "*/arch/arm64/Kconfig" 2>/dev/null \
    | head -1 \
    | sed 's|/arch/arm64/Kconfig||')"

if [[ -z "${KERNEL_SRC}" ]]; then
    echo "[ERROR] Kernel source not found under ${L4T_DIR}/sources"
    echo "        Run prepare.sh first (source_sync.sh)"
    exit 1
fi

echo "         ${KERNEL_SRC}"

#
# Detect cross-compiler
#

echo "[DETECT] Cross-compiler"

if [[ ! -d "${TOOLCHAIN_DIR}" ]]; then
    echo "[ERROR] Toolchain not found at ${TOOLCHAIN_DIR}"
    echo "        Add toolchain to manifest and run download.sh + extract.sh"
    exit 1
fi

CROSS_COMPILE="${TOOLCHAIN_DIR}/bin/aarch64-linux-"

if [[ ! -f "${CROSS_COMPILE}gcc" ]]; then
    echo "[ERROR] Cross-compiler not found: ${CROSS_COMPILE}gcc"
    exit 1
fi

echo "         ${CROSS_COMPILE}"

#
# Build
#

mkdir -p "${KERNEL_OUT}" "${MODULES_OUT}"

MAKE_ARGS=(
    -C "${KERNEL_SRC}"
    ARCH=arm64
    O="${KERNEL_OUT}"
    LOCALVERSION=-tegra
    CROSS_COMPILE="${CROSS_COMPILE}"
)

echo
echo "[BUILD] defconfig"
make "${MAKE_ARGS[@]}" tegra_defconfig

echo
echo "[BUILD] Image"
make "${MAKE_ARGS[@]}" -j"$(nproc)" Image

echo
echo "[BUILD] dtbs"
make "${MAKE_ARGS[@]}" -j"$(nproc)" dtbs

echo
echo "[BUILD] modules"
make "${MAKE_ARGS[@]}" -j"$(nproc)" modules

echo
echo "[BUILD] modules_install"
make "${MAKE_ARGS[@]}" INSTALL_MOD_PATH="${MODULES_OUT}" modules_install

touch "${MARKER}"

echo
echo "[DONE]"
echo
echo "Kernel output : ${KERNEL_OUT}"
echo "Modules output: ${MODULES_OUT}"
