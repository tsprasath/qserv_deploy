#!/bin/sh

# Create node pool for GKE cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options] <pool-name> <machine-type> <size>

  Available options:
    -h          this message

  Create node pool for GKE cluster

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 3 ] ; then
    usage
    exit 2
fi

POOL_NAME=$1
MTYPE=$2
SIZE=$3

gcloud beta container --project "$PROJECT" node-pools create "$POOL_NAME" \
    --cluster "$CLUSTER" --zone "$ZONE" --node-version "1.9.7-gke.6" \
    --machine-type "$MTYPE" --image-type "COS" \
    --disk-type "pd-standard" --disk-size "100" \
    --scopes $SCOPE  \
    --num-nodes "$SIZE" --no-enable-autoupgrade --enable-autorepair
