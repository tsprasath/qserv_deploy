#!/bin/sh

# Configure k8s cluster

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

# Get credentials
mkdir -p "$HOME"/.lsst/qserv-cluster
docker cp kube-master:/etc/kubernetes/admin.conf "$HOME"/.lsst/qserv-cluster/kubeconfig.dind

# Add configuration
ln -sf "$HOME"/.lsst/qserv-cluster/kubeconfig.dind "$HOME"/.lsst/qserv-cluster/kubeconfig
ln -s $DIR/env-infrastructure.dind.sh $HOME/.lsst/qserv-cluster/env-infrastructure.sh 
ln -s $DIR/env.in.sh $HOME/.lsst/qserv-cluster/env.sh

# Create host directory
# FIXME: manage this in env.sh and use emptyDir instead
for i in 1 2 3
do
    docker exec  -- kube-node-${i} sh -c "mkdir -p /qserv/log /qserv/tmp && chown -R 1000:1000 /qserv"
done
