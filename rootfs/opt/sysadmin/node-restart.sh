#!/bin/bash

#  Restart Docker service on all nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

echo "Restart $SERVICE service on node"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo init 6" 
