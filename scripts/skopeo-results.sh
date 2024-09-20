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

if [ -n "${PARAMS_SOURCE_IMAGE_URL}" ] && [ -n "${PARAMS_DESTINATION_IMAGE_URL}" ]; then
    phase "Extracting '${PARAMS_SOURCE_IMAGE_URL}' source image digest"
    source_digest="$(skopeo_inspect "${PARAMS_SOURCE_IMAGE_URL}" "${PARAMS_SRC_TLS_VERIFY}")"
    phase "Source image digest '${source_digest}'"

    phase "Extracting '${PARAMS_DESTINATION_IMAGE_URL}' destination image digest"
    destination_digest="$(skopeo_inspect "${PARAMS_DESTINATION_IMAGE_URL}" "${PARAMS_DEST_TLS_VERIFY}")"
    phase "Destination image digest '${destination_digest}'"
else
    phase "Extracting source and destination image digests for images from url.txt file"
    filename="${WORKSPACES_IMAGES_URL_PATH}/url.txt"
    source_digest=""
    destination_digest=""
    while IFS= read -r line || [ -n "$line" ]
    do
        read -ra SOURCE <<<"${line}"
        source_digest="$source_digest $(skopeo_inspect ${SOURCE[0]} ${PARAMS_SRC_TLS_VERIFY})"
        destination_digest="$destination_digest $(skopeo_inspect ${SOURCE[1]} ${PARAMS_DEST_TLS_VERIFY})"
    done < "$filename"
    # Remove whitespace from the start
    source_digest="${source_digest# }"
    destination_digest="${destination_digest# }"
    phase "Source image digests '${source_digest}'"
    phase "Destination image digests '${destination_digest}'"
fi

printf "%s" "${source_digest}" > "${RESULTS_SOURCE_DIGEST_PATH}"
printf "%s" "${destination_digest}" > "${RESULTS_DESTINATION_DIGEST_PATH}"
