#!/usr/bin/env bash

declare -rx PARAMS_SOURCE="${PARAMS_SOURCE:-}"
declare -rx PARAMS_DESTINATION="${PARAMS_DESTINATION:-}"
declare -rx PARAMS_TLS_VERIFY="${PARAMS_TLS_VERIFY:-}"
declare -rx PARAMS_VERBOSE="${PARAMS_VERBOSE:-}"

declare -rx RESULTS_SOURCE_DIGEST_PATH="${RESULTS_SOURCE_DIGEST_PATH:-}"
declare -rx RESULTS_DESTINATION_DIGEST_PATH="${RESULTS_DESTINATION_DIGEST_PATH:-}"

#
# Asserting Environment
#

exported_or_fail \
    PARAMS_SOURCE \
    PARAMS_DESTINATION \
    RESULTS_SOURCE_DIGEST_PATH \
    RESULTS_DESTINATION_DIGEST_PATH

#
# Skopeo Authentication
#

declare -x REGISTRY_AUTH_FILE=""

docker_config="${HOME}/.docker/config.json"
if [[ -f "${docker_config}" ]]; then
    phase "Setting REGISTRY_AUTH_FILE to '${docker_config}'"
    REGISTRY_AUTH_FILE=${docker_config}
fi

#
# Verbose Output
#

declare -x SKOPEO_DEBUG_FLAG=""

if [[ "${PARAMS_VERBOSE}" == "true" ]]; then
    SKOPEO_DEBUG_FLAG="--debug"
    set -x
fi
