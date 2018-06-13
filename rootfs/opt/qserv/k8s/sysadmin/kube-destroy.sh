#!/bin/bash

# Destroy Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

$QSERV_INSTALL_DIR/k8s/kubectl/delete-nodes.sh || \
    echo "WARN: unable to cleanly delete nodes"

parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- kubeadm reset"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm reset"

# TODO make it at image creation
parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag --transfer sh -c "{}" ::: "$DIR/weave-cleanup-node.sh"

ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sh -s" < "$DIR/weave-cleanup-node.sh"
