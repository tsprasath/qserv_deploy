# Description: allow to customize pods execution
#
# Configuration file copied to orchestration node, in $ORCHESTRATION_DIR
# and then sourced by Kubernetes ochestration node scripts

# VERSION is relative to Qserv repository, it can be:
#  - a git ticket branch but with _ instead of /
#    example: tickets_DM-7139, or dev
#  - a git hash
VERSION=e73191c
# Version of the deployment tool to use
DEPLOY_VERSION=baa0a92-dirty

# `docker run` settings
# =====================

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

# CLUSTER_CONFIG_DIR is a global variable

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
