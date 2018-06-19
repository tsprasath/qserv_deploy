#!/bin/bash

# Help removing qserv database 
# WARN: do not currently remove database but only metadata 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-$HOME/.lsst/qserv-cluster}"
. "$CLUSTER_CONFIG_DIR/env.sh"

SQL="SELECT * FROM qservw_worker.Dbs"
SQL="USE qservw_worker; SHOW TABLES;"

echo "Launch '$SQL' on all nodes"
parallel --tag "kubectl exec {} -c worker -- \
    bash -c \". /qserv/stack/loadLSST.bash && \
    setup mariadbclient && \
    mysql --socket /qserv/run/var/lib/mysql/mysql.sock \
    --user=root --password=changeme \
    -e \\\"$SQL\\\"\"" ::: $WORKER_PODS
