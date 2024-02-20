#!/usr/bin/env bash
#
# Wrapper around "buildah bud" to build and push a container image based on a Dockerfile.
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

phase "Asserting the dockerfile/containerfile '${DOCKERFILE_FULL}' exists"
[[ ! -f "${DOCKERFILE_FULL}" ]] &&
    fail "Dockerfile not found at: '${DOCKERFILE_FULL}'"

phase "Inspecting context '${PARAMS_CONTEXT}'"
[[ ! -d "${PARAMS_CONTEXT}" ]] &&
    fail "CONTEXT param is not found at '${PARAMS_CONTEXT}', on source workspace"

# Handle optional dockerconfig secret
if [[ "${WORKSPACES_DOCKERCONFIG_BOUND}" == "true" ]]; then

    # if config.json exists at workspace root, we use that
    if test -f "${WORKSPACES_DOCKERCONFIG_PATH}/config.json"; then
        export DOCKER_CONFIG="${WORKSPACES_DOCKERCONFIG_PATH}"

        # else we look for .dockerconfigjson at the root
    elif test -f "${WORKSPACES_DOCKERCONFIG_PATH}/.dockerconfigjson"; then
        # ensure .docker exist before the copying the content
        if [ ! -d "$HOME/.docker" ]; then
           mkdir -p "$HOME/.docker"
        fi
        cp "${WORKSPACES_DOCKERCONFIG_PATH}/.dockerconfigjson" "$HOME/.docker/config.json"
        export DOCKER_CONFIG="$HOME/.docker"

        # need to error out if neither files are present
    else
        echo "neither 'config.json' nor '.dockerconfigjson' found at workspace root"
        exit 1
    fi
fi

ENTITLEMENT_VOLUME=""
if [[ "${WORKSPACES_RHEL_ENTITLEMENT_BOUND}" == "true" ]]; then
    ENTITLEMENT_VOLUME="--volume ${WORKSPACES_RHEL_ENTITLEMENT_PATH}:/etc/pki/entitlement"
fi

#
# Build
#

phase "Building '${PARAMS_IMAGE}' based on '${DOCKERFILE_FULL}'"

[[ -n "${PARAMS_BUILD_EXTRA_ARGS}" ]] &&
    phase "Extra 'buildah bud' arguments informed: '${PARAMS_BUILD_EXTRA_ARGS}'"

_buildah bud ${PARAMS_BUILD_EXTRA_ARGS} \
    $ENTITLEMENT_VOLUME \
    --no-cache \
    --file="${DOCKERFILE_FULL}" \
    --tag="${PARAMS_IMAGE}" \
    ${PARAMS_CONTEXT}

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
