#!/usr/bin/env bats

source ./test/helper/helper.sh

declare -rx E2E_SC_PARAMS_SOURCE="${E2E_SC_PARAMS_SOURCE:-}"
declare -rx E2E_SC_PARAMS_DESTINATION="${E2E_SC_PARAMS_DESTINATION:-}"

# Testing the skopeo-copy task,
@test "[e2e] skopeo-copy task copying a image from source to destination registry" {
    # asserting all required configuration is informed
	[ -n "${E2E_SC_PARAMS_SOURCE}" ]
    [ -n "${E2E_SC_PARAMS_DESTINATION}" ]
    [ -n "${E2E_PARAMS_TLS_VERIFY}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E TaskRun
    #

    run tkn task start skopeo-copy \
        --param="SOURCE=${E2E_SC_PARAMS_SOURCE}" \
        --param="DESTINATION=${E2E_SC_PARAMS_DESTINATION}" \
        --param="TLS_VERIFY=${E2E_PARAMS_TLS_VERIFY}" \
        --param="VERBOSE=true" \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
	sleep 30

    # assering the taskrun status, making sure all steps have been successful
    assert_tekton_resource "taskrun" --partial 'All Steps have completed executing'
    # asserting the latest taskrun instacne to inspect the resources against a regular expression
    assert_tekton_resource "taskrun" --regexp $'DESTINATION_DIGEST=\S+\nSOURCE_DIGEST=\S+.*'
}
