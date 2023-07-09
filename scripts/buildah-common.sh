#!/usr/bin/env bash

declare -rx PARAMS_IMAGE="${PARAMS_IMAGE:-}"
declare -rx PARAMS_SUBDIRECTORY="${PARAMS_SUBDIRECTORY:-}"
declare -rx PARAMS_CONTAINERFILE_PATH="${PARAMS_CONTAINERFILE_PATH:-}"
declare -rx PARAMS_STORAGE_DRIVER="${PARAMS_STORAGE_DRIVER:-}"
declare -rx PARAMS_BUILD_EXTRA_ARGS="${PARAMS_BUILD_EXTRA_ARGS:-}"
declare -rx PARAMS_PUSH_EXTRA_ARGS="${PARAMS_PUSH_EXTRA_ARGS:-}"
declare -rx PARAMS_SKIP_PUSH="${PARAMS_SKIP_PUSH:-}"
declare -rx PARAMS_TLS_VERIFY="${PARAMS_TLS_VERIFY:-}"
declare -rx PARAMS_VERBOSE="${PARAMS_VERBOSE:-}"

declare -rx WORKSPACES_SOURCE_PATH="${WORKSPACES_SOURCE_PATH:-}"
declare -rx WORKSPACES_SOURCE_BOUND="${WORKSPACES_SOURCE_BOUND:-}"

declare -rx RESULTS_IMAGE_DIGEST_PATH="${RESULTS_IMAGE_DIGEST_PATH:-}"
declare -rx RESULTS_IMAGE_URL_PATH="${RESULTS_IMAGE_URL_PATH:-}"

#
# Containerfile
#

# exposing the full path to the container file, which by default should be relative to the primary
# workspace, to receive a different container-file location
declare -r containerfile_path_on_ws="${WORKSPACES_SOURCE_PATH}/${PARAMS_CONTAINERFILE_PATH}"
declare -x CONTAINERFILE_PATH_FULL="${CONTAINERFILE_PATH_FULL:-${containerfile_path_on_ws}}"

#
# Asserting Environment
#

[[ -z "${CONTAINERFILE_PATH_FULL}" ]] &&
    fail "unable to find the Containerfile, CONTAINERFILE_PATH may have an incorrect location"

exported_or_fail \
    WORKSPACES_SOURCE_PATH \
    PARAMS_IMAGE

#
# Verbose Output
#

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    set -x
fi
