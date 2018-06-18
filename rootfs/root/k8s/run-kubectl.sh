#!/bin/sh

# Run docker container containing kubectl tools and scripts

# @author  Fabrice Jammes

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
    cat << EOD
Usage: $(basename "$0") [options]
Available options:
  -C            Command to launch inside container
  -K            Path to configuration directory, default to
                \$CLUSTER_CONFIG_DIR env variable value
  -h            This message

Run docker container containing k8s management tools (helm,
kubectl, ...) and scripts.

EOD
}
set -x

# Get the options
while getopts hC:K: c ; do
    case $c in
        C) CMD="${OPTARG}" ;;
        K) CLUSTER_CONFIG_DIR="${OPTARG}" ;;
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

if [ ! -d "$CLUSTER_CONFIG_DIR" ]; then
    echo "ERROR: incorrect CLUSTER_CONFIG_DIR parameter: \"$CLUSTER_CONFIG_DIR\""
    usage
    exit 2
fi

case "$CLUSTER_CONFIG_DIR" in
    /*) ;;
    *) echo "expect absolute path for CLUSTER_CONFIG_DIR" ; exit 2 ;;
esac      

# strip trailing slash
CLUSTER_CONFIG_DIR=$(echo $CLUSTER_CONFIG_DIR | sed 's%\(.*[^/]\)/*%\1%')

# Load VERSION variable (i.e. version of qserv/qserv to use)
. "$CLUSTER_CONFIG_DIR"/env.sh

if [ "$QSERV_CONTAINER" = true  ]; then
    
    if [ -z "${CMD}" ]; then
        echo "Already in a docker container, use kubectl directly"
        exit 1
    fi

    ${CMD}

else

    if [ -z "${CMD}" ]; then
        BASH_OPTS="-it --volume "$DIR"/kubectl/admin:/root/admin-dev"
        CMD="bash"
    fi
    # Launch container
    #
    # Use host network to easily publish k8s dashboard
    IMAGE="qserv/kubectl:$DEPLOY_VERSION"
    docker pull "$IMAGE"
    docker run $BASH_OPTS --net=host \
        --rm \
        --volume "$CLUSTER_CONFIG_DIR":/root/.lsst/qserv-cluster/ \
        "$IMAGE" $CMD
fi
