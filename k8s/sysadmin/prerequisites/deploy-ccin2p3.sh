#!/bin/bash

# Set-up pre-requisites for installing k8s on CC-IN2P3 cluster 

# @author Fabrice Jammes SLAC/IN2P3

set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../../env-cluster.sh"

FULL_SSH_CFG="${PARALLEL_SSH_CFG}.full"

CFG_FILES="/etc/sysctl.d/90-kubernetes.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"

echo "List installed package"
parallel --nonall --tag --slf "$FULL_SSH_CFG" \
    "yum list installed docker-engine kubeadm kubectl kubelet kubernetes-cni"

echo "Install packages"
parallel --nonall --tag --slf "$FULL_SSH_CFG" \
    "sudo yum install docker-engine-1.12.3-1.el7.centos kubeadm-1.9.1-0 \
     kubectl-1.9.1-0 kubelet-1.9.1-0 kubernetes-cni-0.6.0-0"

echo "Disable swap"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo /sbin/swapoff -a"

for f in $CFG_FILES;
do
    echo "Install configuration file $f"
    input_file="$DIR/resource/$(basename $f)"
    parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" --transferfile {} "diff {} $f" ::: $input_file 
    #parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" --transferfile {} "sudo sh -c 'cat {} > $f'" ::: $input_file 
done

echo "Set up systemd configuration"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo /bin/systemctl daemon-reload && \
     sudo /bin/systemctl enable docker && \
     sudo /bin/systemctl enable kubelet && \
     sudo /bin/systemctl restart systemd-sysctl"

