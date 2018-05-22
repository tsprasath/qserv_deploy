#!/bin/sh

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
    -d          remove all host VMs
    -L          run S15 queries
    -k          launch Qserv integration test using kubernetes
    -p          provision Qserv cluster on Openstack

  Create up to date CentOS7 snapshot and use it to provision Qserv cluster on
  Openstack, then install Qserv and launch integration test on it.
  If no option provided, do nothing

  CLUSTER_CONFIG_DIR environment variable point to a directory which contains
  configuration for cloud platform, node, ssh access, and k8s/docker
  specific setup

  Pre-requisites: CLUSTER_CONFIG_DIR env variable be defined,exported and point
                  to a directory containing at least an Openstack RC file named
                  os-openrc.sh

EOD
}

# get the options
while getopts hcdkLp c ; do
    case $c in
        h) usage ; exit 0 ;;
        c) CREATE="TRUE" ;;
        d) DELETE="TRUE" ;;
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

if [ ! -d "$CLUSTER_CONFIG_DIR" ]; then
    echo "ERROR: incorrect CLUSTER_CONFIG_DIR parameter: \"$CLUSTER_CONFIG_DIR\""
    usage
    exit 2
fi

# Check if openstack connection parameters are available
OS_RC_FILE="$CLUSTER_CONFIG_DIR/os-openrc.sh"
if [ -z "$OS_PROJECT_NAME" ]; then
    if [ -f "$OS_RC_FILE" ]; then
        . "$OS_RC_FILE"
    else
        echo "ERROR: Missing Openstack resource file: $OS_RC_FILE"
        exit 1
    fi
    if [ -z "$OS_PROJECT_NAME" ]; then
        echo "ERROR: Incorrect Openstack resource file: $OS_RC_FILE"
        exit 1
    fi
fi

export CLUSTER_CONFIG_DIR
K8S_DIR="$DIR/../k8s"
TF_DIR="$DIR/terraform"

# Choose the configuration file which contains instance parameters
CONF_FILE="${DIR}/${OS_PROJECT_NAME}.conf"


if [ -n "$DELETE" ]; then
    (
    . "$TF_DIR/terraform-setup.sh"
    cd "$TF_DIR"
    terraform destroy
    cd ..
    )
fi


if [ -n "$CREATE" ]; then
    echo "Create up to date snapshot image"
    "$DIR/create-image.py" --cleanup --config "$CONF_FILE" -vv
fi

if [ -n "$PROVISION" ]; then
    echo "Provision Qserv cluster on Openstack"
    . "$TF_DIR/terraform-setup.sh"
    # Terraform performs best in it's own folder
    cd "$TF_DIR"
    terraform init .
    terraform apply --var-file="$TF_DIR/terraform.tfvars" .
    cd ..
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

    # TODO implement ping for pods.qserv
    sleep 20

    if [ -n "$LARGE" ]; then
        echo "Launch large scale tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-large-scale-tests.sh"
    else
        echo "Launch multinode tests"
        "$K8S_DIR"/run-kubectl.sh -C "/root/admin/run-multinode-tests.sh"
    fi
fi
