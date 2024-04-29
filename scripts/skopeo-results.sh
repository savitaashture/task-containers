#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/skopeo-common.sh"

function skopeo_inspect() {
    local image="$1"
    local tls_verify="$2"
    skopeo inspect ${SKOPEO_DEBUG_FLAG} \
        --tls-verify="${tls_verify}" \
        --format='{{ .Digest }}' \
        "${image}"
}

phase "Extracting '${PARAMS_SOURCE_IMAGE_URL}' source image digest"
source_digest="$(skopeo_inspect "${PARAMS_SOURCE_IMAGE_URL}" "${PARAMS_SRC_TLS_VERIFY}")"
phase "Source image digest '${source_digest}'"

phase "Extracting '${PARAMS_DESTINATION_IMAGE_URL}' destination image digest"
destination_digest="$(skopeo_inspect "${PARAMS_DESTINATION_IMAGE_URL}" "${PARAMS_DEST_TLS_VERIFY}")"
phase "Destination image digest '${destination_digest}'"

printf "%s" "${source_digest}" > "${RESULTS_SOURCE_DIGEST_PATH}"
printf "%s" "${destination_digest}" > "${RESULTS_DESTINATION_DIGEST_PATH}"
