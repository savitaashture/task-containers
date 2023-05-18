#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

phase "Preparing the Workspaces, setting the expected ownership and permissions"
#chmod -v 775 "${WORKSPACES_SOURCE_PATH}"

if [[ "${WORKSPACES_SOURCE_BOUND}" == "true" ]]; then
    echo "WORKSPACE EXISTS"
else
    fail "WORKSPACE_SOURCE is not bounded."
fi
