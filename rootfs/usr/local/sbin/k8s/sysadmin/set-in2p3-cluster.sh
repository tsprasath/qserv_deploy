#!/bin/bash

# Set cluster at CC-IN2P3 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

usage() {
    cat << EOD
Usage: $(basename "$0") [options] cluster-name 

Available options:
  -h            This message

Set cluster at CC-IN2P3, cluster-name can be in 'low', 'up', and 'full'

EOD
}

# Get the options
while getopts h c ; do
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

CLUSTER_NAME="$1"

case "$CLUSTER_NAME" in
    full) ;;
    low) ;;
    up) ;;
    *) echo "ERROR: Argument must be in: 'low', 'up', or 'full'" ; exit 2 ;;
esac

rm "$PARALLEL_SSH_CFG" "$ENV_INFRASTRUCTURE"
ln -s "${PARALLEL_SSH_CFG}.${CLUSTER_NAME}" "$PARALLEL_SSH_CFG"
ln -s "${ENV_INFRASTRUCTURE}.${CLUSTER_NAME}" "$ENV_INFRASTRUCTURE"

