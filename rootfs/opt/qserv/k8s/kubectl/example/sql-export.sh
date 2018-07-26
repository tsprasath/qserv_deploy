#!/bin/bash

# Help removing qserv database 
# WARN: do not currently remove database but only metadata 

# @author Fabrice Jammes SLAC/IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

PASSWORD="CHANGEME"
SQL="$1"
# SQL="SELECT * FROM qservw_worker.Dbs"
# SQL="USE qservw_worker; SHOW TABLES;"

echo "Launch '$SQL' on all nodes"
parallel --tag "kubectl exec {} -c mariadb -- \
    bash -c \". /qserv/stack/loadLSST.bash && \
    setup mariadbclient && \
    mysql --socket /qserv/data/mysql/mysql.sock \
    --user=root --password='$PASSWORD' \
    -e \\\"$SQL\\\"\"" ::: master worker-1
