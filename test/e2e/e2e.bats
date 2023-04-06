#!/usr/bin/env bats

source ./test/helper/helper.sh

# Setting the task parameters

export SOURCE_REGISTRY="docker.io/library"
export SOURCE_IMAGE="busybox"                
export SOURCE_TAG="latest"                          
export DESTINATION_REGISTRY="registry.registry.svc.cluster.local:32222"
export DESTINATION_IMAGE="myapp"              
export DESTINATION_TAG="v1"    
export TLS_VERIFY="false"  

# Testing the skopeo-copy task, 
@test "[e2e] using the task to copy an image from remote public registry to local registry" {
    # cleaning up all the existing resources before starting a new taskrun, the test assertion
	# will describe the objects on the current namespace
    run kubectl delete taskrun --all
    assert_success

    # Apply the skopeo-copy task
    run kubectl apply -f templates/task-sc.yaml # Applying the task YAML file
    assert_success

    # 
    # E2E TaskRun
    #
    
    run tkn task start skopeo-copy \
        --param=SOURCE_REGISTRY=$SOURCE_REGISTRY \
        --param=SOURCE_IMAGE=$SOURCE_IMAGE \
        --param=SOURCE_TAG=$SOURCE_TAG \
        --param=DESTINATION_REGISTRY=$DESTINATION_REGISTRY \
        --param=DESTINATION_IMAGE=$DESTINATION_IMAGE \
        --param=DESTINATION_TAG=$DESTINATION_TAG \
        --param=TLS_VERIFY=$TLS_VERIFY \
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
	assert_output --regexp $'DESTINATION_DIGEST=sha256:[a-f0-9]{64}\s+SOURCE_DIGEST=sha256:[a-f0-9]{64}'
}

# Cleaning up the resources
teardown() {
    kubectl delete -f templates/task-sc.yaml
    rm -f tmpl_file
}
