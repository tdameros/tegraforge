#!/usr/bin/env bash

set -euo pipefail

sudo "${L4T_DIR}/tools/l4t_create_default_user.sh" \
    -u tegra \
    -p tegra123 \
    -n jetson \
    --accept-license