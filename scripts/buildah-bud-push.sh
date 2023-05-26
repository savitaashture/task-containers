#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/buildah-prepare.sh"

phase "Executing buildah bud script"

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    set -x
fi

buildah --storage-driver=${PARAMS_STORAGE_DRIVER} bud \
        ${PARAMS_BUILD_EXTRA_ARGS}  \
        --tls-verify=${PARAMS_TLS_VERIFY} --no-cache \
        -f ${PARAMS_CONTAINERFILE_PATH} \
        -t ${PARAMS_IMAGE} \
        ${PARAMS_CONTEXT_SUBDIRECTORY} \
        > workspace/source/image_bud_metadata

if [[ "${PARAMS_SKIP_PUSH}" == "true" ]]; then
    echo "Push skipped"
    exit 0
fi

phase "Executing buildah push script"

buildah --storage-driver=${PARAMS_STORAGE_DRIVER} push \
        ${PARAMS_BUILD_EXTRA_ARGS} --tls-verify=${PARAMS_TLS_VERIFY}  \
        --digestfile workspace/source/image_digest_push ${PARAMS_IMAGE}  \
        ${PARAMS_REGISTRY}