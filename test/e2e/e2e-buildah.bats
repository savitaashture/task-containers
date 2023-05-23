#!/usr/bin/env bats

source ./test/helper/helper.sh

readonly E2E_BUILDAH_PVC_NAME="${E2E_BUILDAH_PVC_NAME:-}"
readonly E2E_BUILDAH_CONTAINERFILE_PATH="${E2E_BUILDAH_CONTAINERFILE_PATH:-}"
readonly E2E_BUILDAH_IMAGE="${E2E_BUILDAH_IMAGE:-}"

# Testing the Buildah task,
@test "[e2e] using the buildah task to build image from Dockerfile" {
    # asserting all required configuration is informed
    [ -n "${E2E_BUILDAH_PVC_NAME}" ]
    [ -n "${E2E_BUILDAH_CONTAINERFILE_PATH}" ]
    [ -n "${E2E_BUILDAH_IMAGE}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E TaskRun
    #

    run kubectl delete pipelinerun --all
    assert_success

    run tkn pipeline start task-buildah \
		--param="IMAGE=${E2E_BUILDAH_IMAGE}" \
		--param="CONTAINERFILE_PATH=${E2E_BUILDAH_CONTAINERFILE_PATH}" \
		--workspace="name=source,claimName=${E2E_BUILDAH_PVC_NAME},subPath=source" \
        --filename=test/e2e/resources/10-pipeline.yaml \
		--showlog >&3
	assert_success
    
    # waiting a few seconds before asserting results
	sleep 15

    #
	# Asserting Status
	#

	readonly tmpl_file="${BASE_DIR}/go-template.tpl"

	cat >${tmpl_file} <<EOS
{{- range .status.conditions -}}
	{{- if and (eq .type "Succeeded") (eq .status "True") }}
		{{ .message }}
	{{- end }}
{{- end -}}
EOS

	# using template to select the requered information and asserting all tasks have been executed
	# without failed or skipped steps
	run tkn pipelinerun describe --output=go-template-file --template=${tmpl_file}
	assert_success
	assert_output --partial '(Failed: 0, Cancelled 0), Skipped: 0'
    
}

# Cleaning up the resources
teardown() {
    rm -f tmpl_file
}
