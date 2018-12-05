# Description: allow to customize pods execution
#
# Configuration file copied to orchestration node, in $ORCHESTRATION_DIR
# and then sourced by Kubernetes ochestration node scripts

# VERSION is relative to Qserv repository, it can be:
#  - a git ticket branch but with _ instead of /
#    example: tickets_DM-7139, or dev
#  - a git hash
VERSION=828ff67

# `docker run` settings
# =====================

# WARN MINIKUBE must have 3 variables below commented
# if not all Qserv pods will use same data directories
# and Qserv may crash

# Data directory location on docker host
HOST_DATA_DIR=/qserv/data

# Qserv temporary directory location on docker host
# HOST_TMP_DIR=/qserv/tmp

# Advanced configuration
# ======================

# QSERV_CFG_DIR is a global variable

# FIXME: infrastructure should be abstracted from k8s
# Parameters related to infrastructure,used to place containers:
# - node hostnames
. "$QSERV_CFG_DIR/env-infrastructure.sh"

# Container image name
CONTAINER_IMAGE="qserv/qserv:${VERSION}"
