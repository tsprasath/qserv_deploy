#!/bin/sh

# Deploy Qserv StatefulSet on Kubernetes cluster

# @author  Benjamin Roziere, IN2P3
# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

CHARTS_DIR="${DIR}/../helm-charts"
HELM_CHART="${CHARTS_DIR}/qserv"

REPLICA_COUNT=$(echo $WORKERS $MASTER | wc -w)

usage() {
  cat << EOD

  Usage: $(basename "$0") [options]

  Available options:
    -h          this message

  Deploy Qserv on Kubernetes

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

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

echo "Installing Helm on cluster"

${DIR}/helm-init.sh

echo "Deploying Qserv statefulset"

if [ "$MASTER" = "-MK-" ]; then
    MINIKUBE="True"
else
    MINIKUBE="False"
fi
# TODO Manage minikube: $MINIKUBE, from ini file
helm upgrade -i $RELEASE_NAME $HELM_CHART --set replicaCount=$REPLICA_COUNT
