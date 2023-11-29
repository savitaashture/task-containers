#!/usr/bin/env bash
# Install OpenShift Pipelines on the current cluster

set -o errexit
set -o nounset
set -o pipefail

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

