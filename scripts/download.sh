#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

source "${ROOT}/scripts/manifest.sh"

JETPACK="${1:-}"

RELEASE="${2:-}"

if [[ -z "$JETPACK" ]]; then
    echo "Usage:"
    echo "download.sh jp6"
    echo "download.sh jp6 r36.4.4"
    exit 1
fi

if [[ -z "$RELEASE" ]]; then
    RELEASE="$(manifest_default_release "$JETPACK")"
fi

TARGET="${ROOT}/downloads/${JETPACK}/${RELEASE}"

mkdir -p "${TARGET}"/{bsp,rootfs,sources}

download_component() {

    local COMPONENT="$1"

    local URL
    local FILE

    URL=$(manifest_url "$JETPACK" "$RELEASE" "$COMPONENT")
    FILE=$(manifest_file_name "$JETPACK" "$RELEASE" "$COMPONENT")

    DEST="${TARGET}/${COMPONENT}/${FILE}"

    if [[ -f "$DEST" ]]; then
        echo "[SKIP] $FILE"
        return
    fi

    echo "[GET ] $FILE"

    wget \
      --continue \
      --show-progress \
      -O "$DEST" \
      "$URL"
}

download_component bsp
download_component rootfs
download_component sources

echo
echo "Done."
echo