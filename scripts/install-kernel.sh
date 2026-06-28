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
    echo "  install-kernel.sh jp5"
    echo "  install-kernel.sh jp5 35.6.4"
    echo ""
    echo "Options:"
    echo "  -f  Force re-install even if already installed"
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
KERNEL_OUT="${BUILD_DIR}/kernel_out"
MODULES_OUT="${BUILD_DIR}/modules_out"
MARKER="${BUILD_DIR}/.tegraforge_install_kernel"

echo
echo "========================================"
echo " TegraForge Install Kernel"
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
        echo "[FORCE] Re-installing (removing marker)"
        rm -f "${MARKER}"
    else
        echo "[SKIP] Already installed (use -f to force)"
        exit 0
    fi
fi

#
# Sanity checks
#

if [[ ! -f "${KERNEL_OUT}/arch/arm64/boot/Image" ]]; then
    echo "[ERROR] Kernel Image not found"
    echo "        Run build.sh first"
    exit 1
fi

if [[ ! -d "${L4T_DIR}" ]]; then
    echo "[ERROR] Linux_for_Tegra not found at ${L4T_DIR}"
    echo "        Run extract.sh first"
    exit 1
fi

#
# Install Image
#

echo "[INSTALL] Image"
cp "${KERNEL_OUT}/arch/arm64/boot/Image" "${L4T_DIR}/kernel/Image"

#
# Install dtbs
#

echo "[INSTALL] dtbs"

DTB_SRC_DIR="${KERNEL_OUT}/arch/arm64/boot/dts/nvidia"
DTB_DST_DIR="${L4T_DIR}/kernel/dtb"

mkdir -p "${DTB_DST_DIR}"

find "${DTB_SRC_DIR}" -maxdepth 1 -name "*.dtb" | while read -r dtb; do
    echo "  -> $(basename "${dtb}")"
    cp "${dtb}" "${DTB_DST_DIR}/"
done

#
# Install modules
#

echo "[INSTALL] modules"

sudo cp -rp "${MODULES_OUT}/lib/modules/." "${L4T_DIR}/rootfs/lib/modules/"

touch "${MARKER}"

echo
echo "[DONE]"
echo
echo "Location: ${L4T_DIR}"
