#!/usr/bin/env bats

source ./test/helper/helper.sh

declare -rx E2E_SC_PARAMS_SOURCE_IMAGE_URL="${E2E_SC_PARAMS_SOURCE_IMAGE_URL:-}"
declare -rx E2E_SC_PARAMS_DESTINATION_IMAGE_URL="${E2E_SC_PARAMS_DESTINATION_IMAGE_URL:-}"

# Testing the skopeo-copy task, verbose = true
@test "[e2e] skopeo-copy task copying a image from source to destination registry with verbose set to true" {
    # asserting all required configuration is informed
	[ -n "${E2E_SC_PARAMS_SOURCE_IMAGE_URL}" ]
    [ -n "${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}" ]
    [ -n "${E2E_PARAMS_SRC_TLS_VERIFY}" ]
    [ -n "${E2E_PARAMS_DEST_TLS_VERIFY}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E TaskRun
    #

    run tkn task start skopeo-copy \
        --param="SOURCE_IMAGE_URL=${E2E_SC_PARAMS_SOURCE_IMAGE_URL}" \
        --param="DESTINATION_IMAGE_URL=${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}" \
        --param="SRC_TLS_VERIFY=${E2E_PARAMS_SRC_TLS_VERIFY}" \
        --param="DEST_TLS_VERIFY=${E2E_PARAMS_DEST_TLS_VERIFY}" \
        --param="VERBOSE=true" \
        --workspace name=images_url,volumeClaimTemplateFile=./test/e2e/resources/workspace-template.yaml \
        --showlog
    assert_success

    # asserting the taskrun status, making sure all steps have been successful
    assert_tekton_resource "taskrun" --partial 'All Steps have completed executing'
    # asserting the latest taskrun instance to inspect the resources against a regular expression
    assert_tekton_resource "taskrun" --regexp $'\S+\n?DESTINATION_DIGEST=\S+\nSOURCE_DIGEST=\S+'
}

# Testing the skopeo-copy task, verbose = false
@test "[e2e] skopeo-copy task copying a image from source to destination registry with verbose set to false" {
    # asserting all required configuration is informed
	[ -n "${E2E_SC_PARAMS_SOURCE_IMAGE_URL}" ]
    [ -n "${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}" ]
    [ -n "${E2E_PARAMS_SRC_TLS_VERIFY}" ]
    [ -n "${E2E_PARAMS_DEST_TLS_VERIFY}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E TaskRun
    #

    run tkn task start skopeo-copy \
        --param="SOURCE_IMAGE_URL=${E2E_SC_PARAMS_SOURCE_IMAGE_URL}" \
        --param="DESTINATION_IMAGE_URL=${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}" \
        --param="SRC_TLS_VERIFY=${E2E_PARAMS_SRC_TLS_VERIFY}" \
        --param="DEST_TLS_VERIFY=${E2E_PARAMS_DEST_TLS_VERIFY}" \
        --param="VERBOSE=false" \
        --workspace name=images_url,volumeClaimTemplateFile=./test/e2e/resources/workspace-template.yaml \
        --showlog
    assert_success

    # assering the taskrun status, making sure all steps have been successful
    assert_tekton_resource "taskrun" --partial 'All Steps have completed executing'
    # asserting the latest taskrun instacne to inspect the resources against a regular expression
    assert_tekton_resource "taskrun" --regexp $'\S+\n?DESTINATION_DIGEST=\S+\nSOURCE_DIGEST=\S+'
}

# Testing the skopeo-copy task, copying multiple images using url.txt file, verbose = true
@test "[e2e] skopeo-copy task copying multiple images from source to destination registry with verbose set to true" {
    # asserting all required configuration is informed
	[ -n "${E2E_SC_PARAMS_SOURCE_IMAGE_URL}" ]
    [ -n "${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}" ]
    [ -n "${E2E_PARAMS_SRC_TLS_VERIFY}" ]
    [ -n "${E2E_PARAMS_DEST_TLS_VERIFY}" ]

    E2E_SC_CONFIG_MAP_TEMPLATE_PATH="./test/e2e/resources/configmap-images-template.yaml"
    E2E_SC_CONFIG_MAP_PATH="${BASE_DIR}/configmap-images.yaml"

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	  # will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    # copying the config map template to the bats temporary directory
    run cp "${E2E_SC_CONFIG_MAP_TEMPLATE_PATH}" "${E2E_SC_CONFIG_MAP_PATH}"
    assert_success

    # filter the template with source and destination images
    run sed -i "s|E2E_SC_PARAMS_SOURCE_IMAGE_URL|${E2E_SC_PARAMS_SOURCE_IMAGE_URL}|" "${E2E_SC_CONFIG_MAP_PATH}"
    assert_success
    run sed -i "s|E2E_SC_PARAMS_DESTINATION_IMAGE_URL|${E2E_SC_PARAMS_DESTINATION_IMAGE_URL}|" "${E2E_SC_CONFIG_MAP_PATH}"
    assert_success

    # create a new config map
    run kubectl apply -f "${E2E_SC_CONFIG_MAP_PATH}"
    assert_success

    #
    # E2E TaskRun
    #

    run tkn task start skopeo-copy \
        --param="SRC_TLS_VERIFY=${E2E_PARAMS_SRC_TLS_VERIFY}" \
        --param="DEST_TLS_VERIFY=${E2E_PARAMS_DEST_TLS_VERIFY}" \
        --param="VERBOSE=true" \
        --workspace name=images_url,config=configmap-images \
        --use-param-defaults \
        --showlog
    assert_success

    # assering the taskrun status, making sure all steps have been successful
    assert_tekton_resource "taskrun" --partial 'All Steps have completed executing'
    # asserting the latest taskrun instacne to inspect the resources against a regular expression
    assert_tekton_resource "taskrun" --regexp $'\S+\n?DESTINATION_DIGEST=\S+\nSOURCE_DIGEST=\S+'
}
