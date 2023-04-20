#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/skopeo-common.sh"

function skopeo_inspect() {
    skopeo inspect ${SKOPEO_DEBUG_FLAG} \
        --tls-verify=${PARAMS_TLS_VERIFY} \
        --format='{{ .Digest }}' \
        ${1}
}

phase "Extracting '${PARAMS_SOURCE}' source image digest"
source_digest="$(skopeo_inspect ${PARAMS_SOURCE})"
phase "Source image digest '${source_digest}'"

phase "Extracting '${PARAMS_DESTINATION}' destination image digest"
destination_digest="$(skopeo_inspect ${PARAMS_DESTINATION})"
phase "Destination image digest '${destination_digest}'"

printf "%s" ${source_digest} >${RESULTS_SOURCE_DIGEST_PATH}
printf "%s" ${destination_digest} >${RESULTS_DESTINATION_DIGEST_PATH}
