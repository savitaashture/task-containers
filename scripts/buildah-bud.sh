#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

phase "Executing buildah bud script"

set -x
exec buildah --storage-driver=${PARAMS_STORAGE_DRIVER} bud \
        ${PARAMS_BUILD_EXTRA_ARGS}  \
        --tls-verify=${PARAMS_TLS_VERIFY} --no-cache \
        -f ${PARAMS_CONTAINERFILE_PATH} \
        -t ${PARAMS_IMAGE} \
        ${PARAMS_CONTEXT_SUBDIRECTORY}