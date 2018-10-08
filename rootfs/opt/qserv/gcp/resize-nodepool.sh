#!/bin/sh

# Resize node pool for GKE cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options] <pool-name> <size>

  Available options:
    -h          this message

  Resize node pool for GKE cluster

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

if [ $# -ne 2 ] ; then
    usage
    exit 2
fi

POOL_NAME=$1
SIZE=$3

gcloud container clusters resize "$CLUSTER" \
    --node-pool "$POOL_NAME" --zone "$ZONE" --size="$SIZE"
