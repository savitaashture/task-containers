#!/usr/bin/env bash
# Install OpenShift Pipelines on the current cluster

set -o errexit
set -o nounset
set -o pipefail

readonly export DEPLOYMENT_TIMEOUT="${DEPLOYMENT_TIMEOUT:-5m}"

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
    exit 1
    ;;
  latest)
    CHANNEL="latest"
    ;;
  *)
    CHANNEL="pipeline-$OSP_VERSION"
    ;;
esac

echo "Installing OpenShift Pipelines from channel ${CHANNEL}"
cat <<EOF | oc apply -f-
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipeline-operator
  namespace: openshift-operators
spec:
  channel: ${CHANNEL}
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Waiting for OpenShift Pipelines Operator to be available"
sleep 60

rollout_status "openshift-pipelines" "tekton-pipelines-controller"
rollout_status "openshift-pipelines" "tekton-pipelines-webhook"

oc get -n openshift-pipelines pods
tkn version
