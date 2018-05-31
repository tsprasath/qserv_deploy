#!/bin/bash

# Destroy Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

"$DIR/../run-kubectl.sh" -C /root/admin/delete-nodes.sh || \
    echo "WARN: unable to cleanly delete nodes"

parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- kubeadm reset"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm reset"


# Reset weave net
# For additional information see:
# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install

CMD="sudo curl -L git.io/weave -o /usr/local/bin/weave && \
    sudo chmod a+x /usr/local/bin/weave && \
    weave reset && \
    sudo rm -f /opt/cni/bin/weave-*"

# TODO make it cleaner
parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "$CMD"

ssh $SSH_CFG_OPT "$ORCHESTRATOR" "$CMD"
