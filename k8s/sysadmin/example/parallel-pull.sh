#!/bin/bash

# Parallel pull of docker image in order to test
# docker registry

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

CLUSTER_CONFIG_DIR="$HOME/.lsst/qserv-cluster"
# GNU parallel ssh configuration
PARALLEL_SSH_CFG="$CLUSTER_CONFIG_DIR/sshloginfile"

usage() {
    cat << EOD
Usage: $(basename "$0") [options] docker-image 

Available options:
  -h            This message

Parallel pull of docker image in order to test
docker registry

EOD
}

# Get the options
while getopts h: c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 1 ] ; then
    usage
    exit 2
fi

DOCKER_IMAGE="$1"

parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "docker pull $DOCKER_IMAGE"

