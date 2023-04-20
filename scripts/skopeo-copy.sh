#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/skopeo-common.sh"

phase "Copying '${PARAMS_SOURCE}' into '${PARAMS_DESTINATION}'"

set -x
exec skopeo copy ${SKOPEO_DEBUG_FLAG} \
    --src-tls-verify=${PARAMS_TLS_VERIFY} \
    --dest-tls-verify=${PARAMS_TLS_VERIFY} \
    ${PARAMS_SOURCE} \
    ${PARAMS_DESTINATION}
