#!/bin/sh

# Creates K8s Volumes and Claims for Master and Workers

# @author Benjamin Roziere, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

usage() {
    cat << EOD

    Usage: $(basename "$0") <hostPath>

    Available options:
      -h          this message

      Create Qserv Volumes and Claims for Path <hostPath>

EOD
}

while getopts hp: c ; do
    case $c in
        h) usage; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 1  ] ; then
    usage
    exit 2
fi

DATA_PATH="$1"

STORAGE_OUTPUT_DIR="$CLUSTER_CONFIG_DIR"/storage

mkdir -p $STORAGE_OUTPUT_DIR

echo "Creating local volume for Qserv Master"

"$DIR"/storage-builder.py -p $DATA_PATH -H $MASTER -d 0 -o $STORAGE_OUTPUT_DIR

echo "Creating local volumes for Qserv Workers"

DATA_ID=1

for host in $WORKERS;
do
    "$DIR"/storage-builder.py -p $DATA_PATH -H $host -d $DATA_ID -o $STORAGE_OUTPUT_DIR
    DATA_ID=$((DATA_ID+1))
done
