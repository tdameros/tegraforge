#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

JETPACK="${1:-}"
RELEASE="${2:-}"
BOARD="${3:-}"

usage()
{
    echo "Usage:"
    echo "  patch.sh jp6 my-board"
    echo "  patch.sh jp6 r36.4.4 my-board"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

#
# Support:
#
# patch.sh jp6 my-board
# patch.sh jp6 r36.4.4 my-board
#

if [[ $# -eq 2 ]]; then
    BOARD="${2}"
    RELEASE="$(manifest_default_release "${JETPACK}")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"
L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

echo
echo "========================================"
echo " TegraForge Patch"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo "Board   : ${BOARD}"
echo

if [[ ! -d "${L4T_DIR}" ]]; then

    echo "[INFO] BSP not prepared"
    echo "[INFO] Running prepare.sh"
    echo

    "${ROOT}/scripts/prepare.sh" \
        "${JETPACK}" \
        "${RELEASE}"
fi

BOARD_DIR="${ROOT}/boards/${BOARD}"
PATCH_DIR="${BOARD_DIR}/patches"

if [[ ! -d "${BOARD_DIR}" ]]; then
    echo "[ERROR] Board not found"
    echo "${BOARD_DIR}"
    exit 1
fi

if [[ ! -d "${PATCH_DIR}" ]]; then
    echo "[INFO] No patches directory"
    exit 0
fi

PATCH_COUNT=$(
    find "${PATCH_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.patch" \
        | wc -l
)

if [[ "${PATCH_COUNT}" -eq 0 ]]; then
    echo "[INFO] No patches found"
    exit 0
fi

MARKER=".tegraforge_patched_${BOARD}"

cd "${L4T_DIR}"

if [[ -f "${MARKER}" ]]; then
    echo "[SKIP] BSP already patched"
    exit 0
fi

echo "[CHECK] Validating patches"
echo

while IFS= read -r patch
do

    echo "  -> $(basename "${patch}")"

    git apply --check "${patch}"

done < <(
    find "${PATCH_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.patch" \
        | sort
)

echo
echo "[APPLY] Applying patches"
echo

while IFS= read -r patch
do

    echo "  -> $(basename "${patch}")"

    git apply "${patch}"

done < <(
    find "${PATCH_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.patch" \
        | sort
)

touch "${MARKER}"

echo
echo "[DONE] BSP patched"
echo

echo "Location:"
echo "${L4T_DIR}"