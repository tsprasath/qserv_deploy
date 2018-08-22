#!/bin/bash

# Launch Qserv multinode tests on Swarm cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

# Build CSS input data
i=1
DN="qserv"
HOSTNAME_PREFIX="worker"
for node in $WORKERS;
do
    CSS_INFO="${CSS_INFO}CREATE NODE worker${i} type=worker port=5012 \
    host=${HOSTNAME_PREFIX}-${i}.${DN}; "
    i=$((i+1))
done

MYSQL_SOCKET="/qserv/data/mysql/mysql.sock"
URL="mysql://qsmaster@localhost/qservCssData?unix_socket=${MYSQL_SOCKET}"

kubectl exec dataloader -c dataloader -- su qserv -l -c ". /qserv/stack/loadLSST.bash && \
    setup qserv_distrib -t qserv-dev && \
    echo \"$CSS_INFO\" | qserv-admin.py -c ${URL} && \
    qserv-test-integration.py -V DEBUG"
