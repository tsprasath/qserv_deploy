#!/bin/sh

# Deploy Qserv StatefulSet on Kubernetes cluster

# @author  Benjamin Roziere, IN2P3
# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

HELM_CHART="${DIR}/qserv"
RELEASE_NAME="qserv"

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

echo "Create kubernetes pod for Qserv statefulset"

helm upgrade -i --dry-run --debug $RELEASE_NAME $HELM_CHART
