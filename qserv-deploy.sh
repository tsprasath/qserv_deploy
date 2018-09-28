#!/bin/sh

# Wrapper for the Qserv deploy container
# Check for needed variables
# @author Benjamin Roziere <benjamin.roziere@clermont.in2p3.fr>

set -e

STABLE_VERSION="0deeeaf"
IMAGE="qserv/deploy:$STABLE_VERSION"

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD

Usage: `basename $0` [options] [cmd]

  Available options:
    -h          this message

  Run a docker container with all the Qserv deployment tools inside.

  Pre-requisites: QSERV_CFG_DIR env variable must be defined and exported.

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ge 2 ] ; then
    usage
    exit 2
elif [ $# -eq 1 ]; then
    CMD=$1
elif [ $# -eq 0 ]; then
    CMD="bash"
fi


SSH_DIR="$HOME/.ssh"
HELM_DIR="$HOME/.helm"

mkdir -p $SSH_DIR $HELM_DIR

CONTAINER_HOME="$HOME"

if [ ! -d "$QSERV_CFG_DIR" ]; then
    >&2 echo "ERROR: Incorrect QSERV_CFG_DIR parameter: \"$QSERV_CFG_DIR\""
    exit 1
fi

MOUNTS="-v $QSERV_CFG_DIR:/qserv-deploy/config "
MOUNTS="$MOUNTS -v $SSH_DIR:$CONTAINER_HOME/.ssh"
MOUNTS="$MOUNTS -v $HELM_DIR:$CONTAINER_HOME/.helm"
MOUNTS="$MOUNTS -v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro"

echo "Starting Qserv deploy on cluster $QSERV_CFG_DIR"

if [ "$QSERV_DEV" = true ]; then
    echo "Running in development mode"
    MOUNTS="$MOUNTS -v $DIR/rootfs/opt/qserv:/opt/qserv"
fi

# Used with minikube to retrieve keys stored in $HOME/.minikube/
if [ "$MOUNT_DOT_MK" = true ]; then
    echo "Mounting $HOME/.minikube inside container"
    MOUNTS="$MOUNTS -v $HOME/.minikube:$HOME/.minikube"
fi

docker run -it --net=host --rm -l config-path=$QSERV_CFG_DIR \
    --user=$(id -u):$(id -g $USER) $MOUNTS \
    "$IMAGE" $CMD
