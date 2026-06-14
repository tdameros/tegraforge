#!/usr/bin/env bash

set -euo pipefail

MANIFEST_DIR="$(dirname "${BASH_SOURCE[0]}")/../manifests"

manifest_file() {

    local JP="$1"

    echo "${MANIFEST_DIR}/${JP}.yaml"
}

manifest_default_release() {

    local JP="$1"

    yq '.default_release' \
        "$(manifest_file "$JP")"
}

manifest_url() {

    local JP="$1"
    local RELEASE="$2"
    local COMPONENT="$3"

    yq \
      ".releases.\"${RELEASE}\".${COMPONENT}.url" \
      "$(manifest_file "$JP")"
}

manifest_file_name() {

    local JP="$1"
    local RELEASE="$2"
    local COMPONENT="$3"

    yq \
      ".releases.\"${RELEASE}\".${COMPONENT}.file" \
      "$(manifest_file "$JP")"
}