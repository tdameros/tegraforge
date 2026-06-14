#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

JETPACK="${1:-}"
RELEASE="${2:-}"

if [[ -z "${JETPACK}" ]]; then
    echo "Usage:"
    echo "  package.sh <jetpack>"
    echo "  package.sh <jetpack> <release>"
    exit 1
fi

if [[ -z "${RELEASE}" ]]; then
    RELEASE="$(manifest_default_release "${JETPACK}")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"
L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

OUT="${ROOT}/output/${JETPACK}/${RELEASE}"

if [[ ! -d "${L4T_DIR}" ]]; then
    echo "[ERROR] Linux_for_Tegra not found"
    echo "${L4T_DIR}"
    exit 1
fi

mkdir -p "${OUT}"

echo
echo "========================================"
echo " TegraForge Package"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo

echo "[INFO] Generating release.json..."

cat > "${OUT}/release.json" <<EOF
{
  "project": "TegraForge",
  "jetpack": "${JETPACK}",
  "release": "${RELEASE}",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "[INFO] Generating README.md..."

cat > "${OUT}/README.md" <<EOF
# TegraForge Flash Package

JetPack : ${JETPACK}
Release : ${RELEASE}

## Extract

tar xf flash-package.tar.gz

## Flash

cd Linux_for_Tegra

sudo ./flash.sh <board-config> internal

Examples:

sudo ./flash.sh jetson-orin-nano-devkit internal

sudo ./flash.sh jetson-orin-nx-devkit internal

sudo ./flash.sh jetson-agx-orin-devkit internal
EOF

echo "[INFO] Creating archive..."

rm -f "${OUT}/flash-package.tar.gz"

pushd "${BUILD_DIR}" >/dev/null

tar czf \
    "${OUT}/flash-package.tar.gz" \
    Linux_for_Tegra

popd >/dev/null

echo
echo "[DONE]"
echo

echo "Package:"
echo "${OUT}/flash-package.tar.gz"
echo