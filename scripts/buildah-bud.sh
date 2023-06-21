#!/usr/bin/env bash
#
# Wrapper around "buildah bud" to build and push a container image based on a Containerfile.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

function _buildah() {
    buildah \
        --storage-driver="${PARAMS_STORAGE_DRIVER}" \
        --tls-verify="${PARAMS_TLS_VERIFY}" \
        ${*}
}

#
# Prepare
#

# making sure the required workspace "source" is bounded, which means its volume is currently mounted
# and ready to use
phase "Inspecting source workspace '${WORKSPACES_SOURCE_PATH}' (PWD='${PWD}')"
[[ "${WORKSPACES_SOURCE_BOUND}" != "true" ]] &&
    fail "Workspace 'source' is not bounded"

# before starting, checking if the Containerfile exists
phase "Checking '${PARAMS_CONTAINERFILE_PATH}' on '${PARAMS_SUBDIRECTORY}' context directory"
[[ ! -f "${PARAMS_CONTAINERFILE_PATH}" ]] &&
    fail "Containerfile not found at: '${WORKSPACES_SOURCE_PATH}/${PARAMS_CONTAINERFILE_PATH}'"

#
# Build
#

phase "Building '${PARAMS_IMAGE}' based on '${PARAMS_CONTAINERFILE_PATH}'"

[[ -n "${PARAMS_BUILD_EXTRA_ARGS}" ]] &&
    phase "Extra 'buildah bud' arguments informed: '${PARAMS_BUILD_EXTRA_ARGS}'"

_buildah bud ${PARAMS_BUILD_EXTRA_ARGS} \
    --no-cache \
    --file="${PARAMS_CONTAINERFILE_PATH}" \
    --tag="${PARAMS_IMAGE}" \
    ${PARAMS_SUBDIRECTORY}

if [[ "${PARAMS_SKIP_PUSH}" == "true" ]]; then
    phase "Skipping pushing '${PARAMS_IMAGE}' to the container registry!"
    exit 0
fi

#
# Push
#

phase "Pushing '${PARAMS_IMAGE}' to the container registry"

[[ -n "${PARAMS_PUSH_EXTRA_ARGS}" ]] &&
    phase "Extra 'buildah bud' arguments informed: '${PARAMS_PUSH_EXTRA_ARGS}'"

# temporary file to store the image digest, information only obtained after pushing the image to the
# container registry
declare -r digest_file="/tmp/buildah-digest.txt"

_buildah push ${PARAMS_PUSH_EXTRA_ARGS} \
    --digestfile="${digest_file}" \
    ${PARAMS_IMAGE} \
    docker://${PARAMS_IMAGE}

#
# Results
#

phase "Inspecting digest report ('${digest_file}')"

[[ ! -r "${digest_file}" ]] &&
    fail "Unable to find digest-file at '${digest_file}'"

declare -r digest_sum="$(cat ${digest_file})"

[[ -z "${digest_sum}" ]] &&
    fail "Digest file '${digest_file}' is empty!"

phase "Successfuly built container image '${PARAMS_IMAGE}' ('${digest_sum}')"
echo -n "${PARAMS_IMAGE}" | tee ${RESULTS_IMAGE_URL_PATH}
echo -n "${digest_sum}" | tee ${RESULTS_IMAGE_DIGEST_PATH}
