#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/skopeo-common.sh"

# Ensure the /tekton/home/.docker directory exists
mkdir -p /workspace/home/.docker

set -x

if [ -n "${PARAMS_SOURCE_IMAGE_URL}" ] && [ -n "${PARAMS_DESTINATION_IMAGE_URL}" ]; then
    phase "Copying '${PARAMS_SOURCE_IMAGE_URL}' into '${PARAMS_DESTINATION_IMAGE_URL}'"
    skopeo copy ${SKOPEO_DEBUG_FLAG} \
        --src-tls-verify="${PARAMS_SRC_TLS_VERIFY}" \
        --dest-tls-verify="${PARAMS_DEST_TLS_VERIFY}" \
        "${PARAMS_SOURCE_IMAGE_URL}" \
        "${PARAMS_DESTINATION_IMAGE_URL}"
elif [ "${WORKSPACES_IMAGES_URL_BOUND}" == "true" ]; then
    phase "Copying using url.txt file"
    # Function to copy multiple images.
    copyimages() {
        filename="${WORKSPACES_IMAGES_URL_PATH}/url.txt"
        [[ ! -f "${filename}" ]] && fail "url.txt file not found at: '${filename}'"
        while IFS= read -r line || [ -n "$line" ]
        do
            read -ra SOURCE <<<"${line}"
            skopeo copy "${SOURCE[@]}" ${SKOPEO_DEBUG_FLAG} --src-tls-verify="${PARAMS_SRC_TLS_VERIFY}" --dest-tls-verify="${PARAMS_DEST_TLS_VERIFY}"
            echo "$line"
        done < "$filename"
    }

    copyimages
else
  fail "Neither Source/Destination image URL parameters nor workspace images_url provided"
fi
