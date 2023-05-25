#!/usr/bin/env bash

phase "Declaring Environment Variables"

declare -rx PARAMS_IMAGE="${PARAMS_IMAGE:-}"
declare -rx PARAMS_REGISTRY="${PARAMS_REGISTRY:-}"
declare -rx PARAMS_STORAGE_DRIVER="${PARAMS_STORAGE_DRIVER:-}"
declare -rx PARAMS_CONTAINERFILE_PATH="${PARAMS_CONTAINERFILE_PATH:-}"
declare -rx PARAMS_CONTEXT_SUBDIRECTORY="${PARAMS_CONTEXT_SUBDIRECTORY:-}"
declare -rx PARAMS_TLS_VERIFY="${PARAMS_TLS_VERIFY:-}"
declare -rx PARAMS_BUILD_EXTRA_ARGS="${PARAMS_BUILD_EXTRA_ARGS:-}"
declare -rx PARAMS_PUSH_EXTRA_ARGS="${PARAMS_PUSH_EXTRA_ARGS:-}"
declare -rx PARAMS_SKIP_PUSH="${PARAMS_SKIP_PUSH:-}"

declare -rx WORKSPACES_SOURCE_PATH="${WORKSPACES_SOURCE_PATH:-}"
declare -rx WORKSPACES_SOURCE_BOUND="${WORKSPACES_SOURCE_BOUND:-}"

declare -rx RESULTS_IMAGE_DIGEST_PATH="${RESULTS_IMAGE_DIGEST_PATH:-}"
declare -rx RESULTS_IMAGE_METADATA_PATH="${RESULTS_IMAGE_METADATA_PATH:-}"
declare -rx RESULTS_IMAGE_URL_PATH="${RESULTS_IMAGE_URL_PATH:-}"

#
# Additional Configuration
#

# full path to the target application source code directory
# declare -rx SOURCE_DIR="${WORKSPACES_SOURCE_PATH}/${PARAMS_CONTEXT_SUBDIRECTORY}"

declare -rx TEKTON_HOME="${TEKTON_HOME:-/tekton/home}"


#
# Asserting Environment
#


declare -ra required_vars=(
    WORKSPACES_SOURCE_PATH
    PARAMS_IMAGE
    PARAMS_CONTAINERFILE_PATH
    PARAMS_SKIP_PUSH
)

for v in "${required_vars[@]}"; do
    [[ -z "${!v}" ]] &&
        fail "'${v}' environment variable is not set!"
done

phase "Declared successfully"