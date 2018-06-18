#!/bin/bash

#  Restart Docker service on all nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

for node in $MASTER $WORKERS $ORCHESTRATOR
do
    echo "modprobe ipvs $node"
	ssh $SSH_CFG_OPT "$node" "sudo -- sh -c 'modprobe ip_vs && modprobe ip_vs_rr && \
        modprobe ip_vs_wrr && modprobe ip_vs_sh \
        && modprobe nf_conntrack_ipv4'"
done

