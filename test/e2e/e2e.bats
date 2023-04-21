#!/usr/bin/env bats

source ./test/helper/helper.sh

PARAMS_SOURCE=$(echo ${E2E_SC_PARAMS_SOURCE:-} | tr -d '"')
PARAMS_DESTINATION=$(echo ${E2E_SC_PARAMS_DESTINATION:-} | tr -d '"')
PARAMS_TLS_VERIFY=$(echo ${E2E_SC_PARAMS_TLS_VERIFY:-} | tr -d '"')

# Testing the skopeo-copy task,
@test "[e2e] using the task to copy an image from remote public registry to local registry" {
    # asserting all required configuration is informed
	[ -n "${PARAMS_SOURCE}" ]
    [ -n "${PARAMS_DESTINATION}" ]
    [ -n "${PARAMS_TLS_VERIFY}" ]

    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    #
    # E2E TaskRun
    #
    
    run tkn task start skopeo-copy \
        --param="SOURCE=${PARAMS_SOURCE}" \
        --param="DESTINATION=${PARAMS_DESTINATION}" \
        --param="TLS_VERIFY=${PARAMS_TLS_VERIFY}" \
        --param="VERBOSE=true" \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
	sleep 25

    #
    # Asserting TaskRun Status
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
	run tkn taskrun describe --output=go-template-file --template=${tmpl_file}
	assert_success
	assert_success --partial 'All Steps have completed executing'


    # Asserting Results

    cat >${tmpl_file} <<EOS
{{- range .status.taskResults -}}
    {{ printf "%s=%s\n" .name .value }}
{{- end -}}
EOS
	run tkn taskrun describe --output=go-template-file --template=${tmpl_file}
	assert_success
	assert_output --regexp $'^DESTINATION_DIGEST=\S+\nSOURCE_DIGEST=\S+.*'
}

# Cleaning up the resources
teardown() {
    kubectl delete -f templates/task-sc.yaml
    rm -f tmpl_file
}
