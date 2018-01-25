#!/bin/bash

# Destroy Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

"$DIR/../run-kubectl.sh" -C /root/admin/delete-nodes.sh || \
    echo "WARN: unable to cleanly delete nodes"

ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm reset"

parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- kubeadm reset"
