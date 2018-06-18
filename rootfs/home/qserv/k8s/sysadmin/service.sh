#!/bin/bash

#  parallel management of service service on all nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

SERVICE=docker
#SERVICE=kubelet

ACTION=stop

echo "$ACTION $SERVICE service on node"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo /bin/systemctl  daemon-reload && \
     sudo /bin/systemctl ${ACTION} ${SERVICE}.service && \
     echo \"$SERVICE\" ${ACTION}: ok"

