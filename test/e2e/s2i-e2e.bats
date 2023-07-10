#!/usr/bin/env bats

source ./test/helper/helper.sh

declare -rx E2E_S2I_PVC_NAME="${E2E_S2I_PVC_NAME:-}"
declare -rx E2E_S2I_PVC_SUBPATH="${E2E_S2I_PVC_SUBPATH:-}"

# E2E tests parameters for the test pipeline
declare -rx E2E_S2I_PARAMS_URL="${E2E_S2I_PARAMS_URL:-}"
declare -rx E2E_S2I_PARAMS_REVISION="${E2E_S2I_PARAMS_REVISON:-}"
declare -rx E2E_S2I_PARAMS_IMAGE="${E2E_S2I_PARAMS_IMAGE:-}"

@test "[e2e] pipeline-run using s2i task" {
    [ -n "${E2E_S2I_PVC_NAME}" ]
    [ -n "${E2E_S2I_PVC_SUBPATH}" ]
    [ -n "${E2E_S2I_PARAMS_URL}" ]
    [ -n "${E2E_S2I_PARAMS_REVISION}" ]
    [ -n "${E2E_S2I_PARAMS_IMAGE}" ]
    [ -n "${E2E_PARAMS_TLS_VERIFY}" ]

    # cleaning up existing resources before starting a new pipelinerun
    run kubectl delete pipelinerun --all
    assert_success

    tkn pipeline start task-s2i \
        --param="URL=${E2E_S2I_PARAMS_URL}" \
        --param="REVISION=${E2E_S2I_PARAMS_REVISION}" \
        --param="IMAGE=${E2E_S2I_PARAMS_IMAGE}" \
        --param="TLS_VERIFY=${E2E_PARAMS_TLS_VERIFY}" \
        --param="VERBOSE=true" \
        --workspace="name=source,claimName=${E2E_S2I_PVC_NAME},subPath=${E2E_S2I_PVC_SUBPATH}" \
        --filename=test/e2e/resources/pipeline-s2i.yaml \
        --showlog >&3
    assert_success

    # waiting a few seconds before asserting results
    sleep 30

    # assering the pipelinerun status, making sure all steps have been successful
    assert_tekton_resource "pipelinerun" --partial '(Failed: 0, Cancelled 0), Skipped: 0'
    # asserting the latest taskrun instacne to inspect the resources against a regular expression
    assert_tekton_resource "taskrun" --regexp $'IMAGE_DIGEST=\S+.\nIMAGE_URL=\S+*'
}
