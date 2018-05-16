#!/bin/bash

# Test script which performs the following tasks:

# Create image
# Boot instances
# Launch Qserv containers
# Lauch integration tests

# @author  Oualid Achbal, IN2P3
# @author  Fabrice Jammes, IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
  cat << EOD

Usage: `basename $0` [options]

  Available options:
    -h          this message
    -c          update CentOS7/Docker snapshot
    -L          run S15 queries
    -k          launch Qserv integration test using kubernetes
    -p          provision Qserv cluster on Openstack

  Create up to date CentOS7 snapshot and use it to provision Qserv cluster on
  Openstack, then install Qserv and launch integration test on it.
  If no option provided, do nothing


  Pre-requisites: Openstack RC file need to be sourced.

EOD
}

# get the options
while getopts hckLpsS c ; do
    case $c in
        h) usage ; exit 0 ;;
        c) CREATE="TRUE" ;;
        k) KUBERNETES="TRUE" ;;
        L) LARGE="TRUE" ;;
        p) PROVISION="TRUE" ;;
        \?) usage ; exit 2 ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

# Check if openstack connection parameters are available
if [ -z "$OS_PROJECT_NAME" ]; then
    echo "ERROR: Openstack resource file not sourced"
    exit 1
fi

export CLUSTER_CONFIG_DIR="$HOME/.lsst/qserv-cluster/${OS_PROJECT_NAME}"
K8S_DIR="$DIR/../k8s"


# Choose the configuration file which contains instance parameters
CONF_FILE="${DIR}/${OS_PROJECT_NAME}.conf"

if [ -n "$CREATE" ]; then
    echo "Create up to date snapshot image"
    "$DIR/create-image.py" --cleanup --config "$CONF_FILE" -vv
fi

if [ -n "$PROVISION" ]; then
    echo "Provision Qserv cluster on Openstack"
    "$DIR/provision-qserv.py" --cleanup \
        --config "$CONF_FILE" \
        -vv
    mkdir -p "$CLUSTER_CONFIG_DIR"
    cp "$DIR/ssh_config" "$CLUSTER_CONFIG_DIR"
    cp "$DIR/env-infrastructure.sh" "$CLUSTER_CONFIG_DIR"
    "$K8S_DIR/sysadmin/create-gnuparallel-slf.sh"
fi

if [ -n "$KUBERNETES" ]; then

    # Trigger special behaviour for Openstack
    export OPENSTACK=true

    echo "Create Kubernetes cluster"
    # require sudo access on nodes
   "$K8S_DIR"/sysadmin/kube-destroy.sh

    # require DEPLOY_VERSION value to install weave
    ENV_FILE="$CLUSTER_CONFIG_DIR/env.sh"
    cp "$K8S_DIR/env.in.sh" "$ENV_FILE"
   "$K8S_DIR"/sysadmin/kube-create.sh

    echo "Configure and launch Qserv"
    # require access to kubectl configuration
    . "$ENV_FILE"
    echo "Use qserv version: qsev/qserv:$VERSION"
    echo "Use qserv_deploy version: qserv/kubectl:$DEPLOY_VERSION"

    if [ -n "$LARGE" ]; then
        sed -i "s,# HOST_DATA_DIR=/qserv/data,HOST_DATA_DIR=/mnt/qserv/data," \
            "$ENV_FILE"
    fi
    "$K8S_DIR"/start.sh

    if [ -n "$LARGE" ]; then
        echo "Launch large scale tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-large-scale-tests.sh"
    else
        echo "Launch multinode tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-multinode-tests.sh"
    fi
fi
