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

  Pre-requisites: QSERV_CFG_DIR env variable must be defined and exported.

EOD
}

SSH_DIR="$HOME/.ssh"
CONTAINER_HOME="$HOME"

if [ ! -d "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Incorrect QSERV_CFG_DIR parameter: \"$QSERV_CFG_DIR\""
    exit 1
fi

MOUNTS="-v $QSERV_CFG_DIR:/qserv-deploy/config -v $SSH_DIR:$CONTAINER_HOME/.ssh:ro -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro"

echo "Starting Qserv deploy on cluster $QSERV_CFG_DIR"

if [ "$QSERV_DEV" = true ]; then
    echo "Running in development mode"
    MOUNTS="$MOUNTS -v $DIR/rootfs/opt/qserv:/opt/qserv"
fi

docker run -it --net=host --rm -l config-path=$QSERV_CFG_DIR --user=$(id -u):$(id -g $USER) $MOUNTS qserv/deploy:4849312