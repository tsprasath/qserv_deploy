#!/bin/bash

#  parallel management of service service on all nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

CLUSTER_CONFIG_DIR="$HOME/.lsst/qserv-cluster"
# GNU parallel ssh configuration
PARALLEL_SSH_CFG="$CLUSTER_CONFIG_DIR/sshloginfile"

SERVICE=docker
#SERVICE=kubelet

ACTION=stop

echo "$ACTION $SERVICE service on node"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo /bin/systemctl  daemon-reload && \
     sudo /bin/systemctl ${ACTION} ${SERVICE}.service && \
     echo \"$SERVICE\" ${ACTION}: ok"

