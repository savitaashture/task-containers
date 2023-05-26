#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

# file storing image digest and tag
filename="workspace/source/image_bud_metadata"

if [ -e "$filename" ]; then
  echo "File exists: $filename"
else
  echo "File does not exist: $filename"
  exit 1
fi

phase "Extracting '${PARAMS_IMAGE}'  image metadata"
## Verify if the image is successfully built

# Getting last 2 lines from filename
tmp=$(tail -n 2 $filename | tr '\n ' '-')

printf "%s" ${PARAMS_IMAGE} >${RESULTS_IMAGE_URL_PATH}
printf "%s" ${tmp} >${RESULTS_IMAGE_METADATA_PATH}

if [[ "${PARAMS_SKIP_PUSH}" == "false" ]] &&  [ -e "workspace/source/image_digest_push" ] ; then
    printf "%s" $(cat workspace/source/image_digest_push) >${RESULTS_IMAGE_DIGEST_PATH}
fi

