#!/bin/bash

# Create Kubernetes cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

echo "Create Kubernetes cluster"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- systemctl start kubelet"
TOKEN=$(ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm token generate")
# TODO add option for openstack
SSH_TUNNEL_OPT="--apiserver-cert-extra-sans=localhost"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "sudo -- kubeadm init $SSH_TUNNEL_OPT --token '$TOKEN'"

"$DIR"/export-kubeconfig.sh
ssh $SSH_CFG_OPT "$ORCHESTRATOR" "mkdir -p \$HOME/.kube && \
    sudo cp /etc/kubernetes/admin.conf \$HOME/.kube/config && \
    sudo chown -R qserv:qserv \$HOME/.kube && \
	KUBEVER=\$(kubectl version | base64 | tr -d '\n') && \
    kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=\$KUBEVER\""

HASH=$(ssh $SSH_CFG_OPT "$ORCHESTRATOR" "openssl x509 -pubkey -in \
    /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null \
	| openssl dgst -sha256 -hex | sed 's/^.* //'")

JOIN_CMD="kubeadm join --token '$TOKEN' \
    --discovery-token-ca-cert-hash 'sha256:$HASH' \
    $ORCHESTRATOR:6443"

# Join Kubernetes nodes
parallel --nonall --slf "$PARALLEL_SSH_CFG" --tag "sudo -- systemctl start kubelet && \
    sudo -- $JOIN_CMD"
