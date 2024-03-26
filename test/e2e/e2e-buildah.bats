#!/usr/bin/env bats

source ./test/helper/helper.sh

declare -rx E2E_BUILDAH_PVC_NAME="${E2E_BUILDAH_PVC_NAME:-}"
declare -rx E2E_BUILDAH_PARAMS_IMAGE="${E2E_BUILDAH_PARAMS_IMAGE:-}"

# Testing the Buildah task,
@test "[e2e] buildah task is able to build and push a container image" {
    # asserting all required configuration is informed
    [ -n "${E2E_BUILDAH_PARAMS_IMAGE}" ]
    [ -n "${E2E_PARAMS_TLS_VERIFY}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
    # will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E Pipeline
    #

    run kubectl delete pipelinerun --all
    assert_success

    run tkn pipeline start task-buildah \
        --param="IMAGE=${E2E_BUILDAH_PARAMS_IMAGE}" \
        --param="TLS_VERIFY=${E2E_PARAMS_TLS_VERIFY}" \
        --param="VERBOSE=true" \
	--workspace name=source,volumeClaimTemplateFile=./test/e2e/resources/workspace-template.yaml \
        --filename=test/e2e/resources/pipeline-buildah.yaml \
        --showlog >&3
    assert_success

    # waiting a few seconds before asserting results
    sleep 30

    # assering the pipelinerun status, making sure all steps have been successful
    assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
    # asserting the latest taskrun instacne to inspect the resources against a regular expression'
    assert_tekton_resource "taskrun" --regexp $'\S+\n?IMAGE_DIGEST=\S+.\nIMAGE_URL=\S+*'
}
