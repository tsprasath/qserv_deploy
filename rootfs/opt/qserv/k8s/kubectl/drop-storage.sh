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

    Usage: $(basename "$0") <volume_type>

    Available options:
      -h          this message

      Drop Qserv Volumes and Claims for volume type <volume_type>

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

VOLUME_TYPE="$1"

DATA_ID=0

for host in $MASTER $WORKERS;
do
    kubectl delete pv "qserv-${VOLUME_TYPE}-pv-${DATA_ID}"
    kubectl delete pvc "qserv-${VOLUME_TYPE}-qserv-${DATA_ID}"
    DATA_ID=$((DATA_ID+1))
done
kubectl delete -f "${DIR}/yaml/qserv-storageclass.yaml"
