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
BOARD="${3:-}"

usage()
{
    echo "Usage:"
    echo "  files.sh jp6 my-board"
    echo "  files.sh jp6 r36.4.4 my-board"
    echo ""
    echo "Options:"
    echo "  -f  Force re-copy files even if already applied"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

#
# Support:
#
# files.sh jp6 my-board
# files.sh jp6 r36.4.4 my-board
#

if [[ $# -eq 2 ]]; then
    BOARD="${2}"
    RELEASE="$(manifest_default_release "${JETPACK}")"
fi

BUILD_DIR="${ROOT}/build/${JETPACK}/${RELEASE}"
L4T_DIR="${BUILD_DIR}/Linux_for_Tegra"

echo
echo "========================================"
echo " TegraForge Files"
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

FILES_DIR="${BOARD_DIR}/files"
BOARD_NAME="$(basename "${BOARD_DIR}")"
MARKER=".tegraforge_files_${BOARD_NAME}"

if [[ ! -d "${BOARD_DIR}" ]]; then
    echo "[ERROR] Board not found"
    echo "${BOARD_DIR}"
    exit 1
fi

if [[ ! -d "${FILES_DIR}" ]]; then
    echo "[INFO] No files directory"
    exit 0
fi

FILE_COUNT=$(find "${FILES_DIR}" -type f | wc -l | tr -d ' ')

if [[ "${FILE_COUNT}" -eq 0 ]]; then
    echo "[INFO] No files found"
    exit 0
fi

cd "${L4T_DIR}"

if [[ -f "${MARKER}" ]]; then
    if [[ "${FORCE}" == true ]]; then
        echo "[FORCE] Re-copying files (removing marker)"
        rm -f "${MARKER}"
    else
        echo "[SKIP] Files already applied (use -f to force)"
        exit 0
    fi
fi

echo "[COPY] Copying board files"
echo

while IFS= read -r src_file; do
    rel_path="${src_file#${FILES_DIR}/}"
    dst_file="${L4T_DIR}/${rel_path}"

    if [[ -f "${dst_file}" ]]; then
        echo "  [WARN] Overwriting: ${rel_path}"
    else
        echo "  -> ${rel_path}"
    fi

    sudo mkdir -p "$(dirname "${dst_file}")"
    sudo cp -p "${src_file}" "${dst_file}"

done < <(find "${FILES_DIR}" -type f | sort)

touch "${MARKER}"

echo
echo "[DONE] ${FILE_COUNT} file(s) copied"
echo

echo "Location:"
echo "${L4T_DIR}"
