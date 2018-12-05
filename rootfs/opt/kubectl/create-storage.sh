#!/bin/sh

# Creates K8s Volumes and Claims for Master and Workers

# @author Benjamin Roziere, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

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

if [ "$GKE" = true ]; then
    exit
elif [ "$MINIKUBE" = true ]; then
    exit
fi

DATA_PATH="$1"

STORAGE_OUTPUT_DIR="$QSERV_CFG_DIR"/storage

mkdir -p $STORAGE_OUTPUT_DIR

echo "Creating local volumes for Qserv nodes"

DATA_ID=0

for host in $MASTER $WORKERS;
do
    if [ "$MINIKUBE" = true ]; then
        OPT_HOST=
    else
        OPT_HOST="-H $host"
    fi
    "$DIR"/storage-builder.py -p "$DATA_PATH" $OPT_HOST -d "$DATA_ID" -o "$STORAGE_OUTPUT_DIR"
    DATA_ID=$((DATA_ID+1))
done

DATA_ID=0

kubectl apply -f "${DIR}/yaml/qserv-storageclass.yaml"
for host in $MASTER $WORKERS;
do
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pv-${DATA_ID}.yaml"
    kubectl apply -f "${STORAGE_OUTPUT_DIR}/qserv-data-pvc-${DATA_ID}.yaml"
    DATA_ID=$((DATA_ID+1))
done
