#!/usr/bin/env bash

set -euo pipefail

SOURCE_ROOT_DIR="$(pwd)"
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
BOARD="${3:-}"

usage()
{
    echo "Usage:"
    echo "  hooks.sh jp6 my-board"
    echo "  hooks.sh jp6 r36.4.4 my-board"
    echo ""
    echo "Options:"
    echo "  -f  Force re-apply hooks even if already apply"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

#
# Support:
#
# hooks.sh jp6 my-board
# hooks.sh jp6 r36.4.4 my-board
#

if [[ $# -eq 2 ]]; then
    BOARD="${2}"
    RELEASE="$(manifest_default_release "${JETPACK}")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"
L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

echo
echo "========================================"
echo " TegraForge Hooks"
echo "========================================"
echo
echo "JetPack : ${JETPACK}"
echo "Release : ${RELEASE}"
echo "Board   : ${BOARD}"
echo

case "${BOARD}" in
    */*|/*)
        BOARD_DIR="$(realpath "${BOARD}")"
        ;;
    *)
        BOARD_DIR="${ROOT}/boards/${BOARD}"
        ;;
esac

HOOK_DIR="${BOARD_DIR}/hooks"
BOARD_NAME="$(basename "${BOARD_DIR}")"

if [[ ! -d "${BOARD_DIR}" ]]; then
    echo "[ERROR] Board not found"
    echo "${BOARD_DIR}"
    exit 1
fi

if [[ ! -d "${HOOK_DIR}" ]]; then
    echo "[INFO] No hooks directory"
    exit 0
fi

HOOK_COUNT=$(
    find "${HOOK_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.sh" \
        | wc -l
)

if [[ "${HOOK_COUNT}" -eq 0 ]]; then
    echo "[INFO] No hooks found"
    exit 0
fi

MARKER=".tegraforge_hooks_${BOARD_NAME}"

cd "${L4T_DIR}"
git init

if [[ -f "${MARKER}" ]]; then
    if [[ "${FORCE}" == true ]]; then
        echo "[FORCE] Re-applying hooks (removing marker)"
        rm -f "${MARKER}"
    else
        echo "[SKIP] Hooks already executed (use -f to force)"
        exit 0
    fi
fi

export ROOT
export JETPACK
export RELEASE
export BOARD
export SOURCE_ROOT_DIR
export BUILD_DIR
export L4T_DIR

echo "[RUN ] Executing hooks"
echo

while IFS= read -r hook
do

    echo "  -> $(basename "${hook}")"

    chmod +x "${hook}"

    "${hook}"

    echo

done < <(
    find "${HOOK_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.sh" \
        | sort
)

touch "${MARKER}"

echo
echo "[DONE] Hooks executed"
echo

echo "Location:"
echo "${L4T_DIR}"