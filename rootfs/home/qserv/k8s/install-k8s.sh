#!/bin/sh

# Start k8s cluster

set -e
set -x

# FIXME: 192.168.0.0/16 causes problems with Travis(?)
export POD_NETWORK_CIDR="10.244.0.0/16"

# Start dind cluster
cd "$HOME" 
wget https://cdn.rawgit.com/Mirantis/kubeadm-dind-cluster/master/fixed/dind-cluster-v1.8.sh
chmod +x dind-cluster-v1.8.sh
export NUM_NODES=3
"$HOME"/dind-cluster-v1.8.sh up
