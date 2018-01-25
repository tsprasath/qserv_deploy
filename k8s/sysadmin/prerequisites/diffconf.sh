#!/bin/bash

# Set-up pre-requisites for installing k8s on CC-IN2P3 cluster 

# @author Fabrice Jammes SLAC/IN2P3

set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../../env-cluster.sh"

FULL_SSH_CFG="${PARALLEL_SSH_CFG}.full"

parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "/sbin/sysctl net.bridge.bridge-nf-call-iptables"


CFG_FILES="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"

for f in $CFG_FILES;
do
    echo "Install configuration file $f"
    input_file="$DIR/resource/$(basename $f)"
    parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" --transferfile {} "diff {} $f" ::: $input_file 
    #parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" --transferfile {} "sudo sh -c 'cat {} > $f'" ::: $input_file 
done

