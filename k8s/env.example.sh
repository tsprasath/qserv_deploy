# Configuration file copied to orchestration node, in $ORCHESTRATION_DIR
# and then sourced by Kubernetes ochestration node scripts
# Allow to customize pods execution

# VERSION can be a git ticket branch but with _ instead of /
# example: tickets_DM-7139, or dev
VERSION=dev
MARIADB_VERSION=10.1.25
# Version of the deplyment tool to use
DEPLOY_VERSION=dev

# `docker run` settings
# =====================

# Customized configuration templates directory location
# on docker host, optional
# See <qserv-src-dir>/doc/source/HOW-TO/docker-custom-configuration.rst
# for additional information
HOST_CUSTOM_DIR=/qserv/custom

# Data directory location on docker host
# HOST_DATA_DIR=/qserv/data

# Log directory location on docker host
HOST_LOG_DIR=/qserv/log

# Qserv temporary directory location on docker host
HOST_TMP_DIR=/qserv/tmp

# Use for debugging purpose
# Alternate command to execute at container startup
# in order no to launch Qserv at container startup
#ALT_CMD="tail -f /dev/null"

# Advanced configuration
# ======================

# Directory containing infrastructure specification
# (k8s configuration files, orchestration parameters)
CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-$HOME/.lsst/qserv-cluster}"

# FIXME: infrastructure should be abstracted from k8s
# Parameters related to infrastructure,used to place containers:
# - node hostnames
. "$CLUSTER_CONFIG_DIR/env-infrastructure.sh"

# Container image name
CONTAINER_IMAGE="qserv/qserv:${VERSION}"

# Pods names
# ==========

MASTER_POD='master'
WORKER_POD_FORMAT='worker-%g'

# List of worker pods (and containers) names
j=1
WORKER_PODS=''
for host in $WORKERS;
do
    WORKER_PODS="$WORKER_PODS worker-$j"
    j=$((j+1));
done
