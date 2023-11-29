#!/usr/bin/env bash
# Install OpenShift Pipelines on the current cluster

set -o errexit
set -o nounset
set -o pipefail

readonly export DEPLOYMENT_TIMEOUT="${DEPLOYMENT_TIMEOUT:-5m}"

function fail() {
    echo "ERROR: ${*}" >&2
    exit 1
}

function rollout_status() {
    local namespace="${1}"
    local deployment="${2}"

    if ! kubectl --namespace="${namespace}" --timeout=${DEPLOYMENT_TIMEOUT} \
         rollout status deployment "${deployment}"; then
        fail "'${namespace}/${deployment}' is not deployed as expected!"
    fi
}

OSP_VERSION=${1:-latest}
shift

CHANNEL=""

case "$OSP_VERSION" in
    nightly)
	echo "Not supporting nightly just yet"
	# FIXME add support for it
	exit 0
	;;
    latest)
	CHANNEL="latest"
	;;
    *)
	CHANNEL="pipelines-$OSP_VERSION"
	;;
esac

echo "Installing OpenShift Pipelines from channel ${CHANNEL}"
cat <<EOF | oc apply -f-
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator-rh
  namespace: openshift-operators
spec:
  channel: ${CHANNEL}
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# FIXME(vdemeester) do better than waiting 2m for the namespace to appear
echo "Waiting for OpenShift Pipelines Operator to be available"
sleep 120

rollout_status "openshift-pipelines" "tekton-pipelines-controller"
rollout_status "openshift-pipelines" "tekton-pipelines-webhook"

oc get -n openshift-pipelines pods
tkn version

# Make sure we are on the default project
oc project default
