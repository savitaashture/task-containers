#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/buildah-common.sh"

# function buildah_inspect() {
#     buildah inspect --format='{{ .FromImageDigest }}' \
#         ${1}
# }

# file storing image digest and tag
filename="workspace/source/image_digest"

if [ -e "$filename" ]; then
  echo "File exists: $filename"
else
  echo "File does not exist: $filename"
  exit 1
fi

phase "Extracting '${PARAMS_IMAGE}'  image digest"
## Verify if the image is successfully built

# Getting last 2 lines from filename
tmp=$(tail -n 2 $filename)

printf "%s" ${PARAMS_IMAGE} >${RESULTS_IMAGE_URL_PATH}
printf "%s" ${tmp} >${RESULTS_IMAGE_DIGEST_PATH}

