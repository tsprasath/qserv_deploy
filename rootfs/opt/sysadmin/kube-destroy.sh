#!/bin/bash

# Destroy Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

"$DIR"/../kubectl/delete-nodes.sh || \
    echo "WARN: unable to cleanly delete nodes"

parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- kubeadm reset"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm reset"

# Remote path must be writable
cp  "$DIR/weave-cleanup-node.sh" "/tmp"
parallel --onall --slf "$PARALLEL_SSH_CFG" --tag --transfer sh -c "{}" ::: "/tmp/weave-cleanup-node.sh"

ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sh -s" < "$DIR/weave-cleanup-node.sh"
