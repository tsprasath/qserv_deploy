#!/bin/sh

# Wrapper for the Qserv deploy container
# Check for needed variables
# @author Benjamin Roziere <benjamin.roziere@clermont.in2p3.fr>

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0`

  Run a docker container with all the Qserv deployment tools inside.

  Pre-requisites: CLUSTER_CONFIG_DIR env variable must be defined and exported.

EOD
}

SSH_DIR="$HOME/.ssh"
CONTAINER_HOME="$HOME"

if [ ! -d "$CLUSTER_CONFIG_DIR" ]; then
    >&2 echo "ERROR: Incorrect CLUSTER_CONFIG_DIR parameter: \"$CLUSTER_CONFIG_DIR\""
    exit 1
fi

MOUNTS="-v $CLUSTER_CONFIG_DIR:$CONTAINER_HOME/.qserv -v $SSH_DIR:$CONTAINER_HOME/.ssh:ro -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro"

echo "Starting Qserv deploy on cluster $CLUSTER_CONFIG_DIR"

if [ "$QSERV_DEV" = true ]; then
    echo "Running in development mode"
    MOUNTS="$MOUNTS -v $DIR/rootfs/opt/qserv:/opt/qserv"
fi

docker run -it --rm -l config-path=$CLUSTER_CONFIG_DIR --user=$(id -u):$(id -g $USER) -w $CONTAINER_HOME -e CLUSTER_CONFIG_DIR=$CONTAINER_HOME/.qserv -e KUBECONFIG=$CONTAINER_HOME/.qserv/kubeconfig $MOUNTS qserv/deploy
