#!/bin/bash

# Start Qserv replication worker service inside pod

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

# worker_id.txt is created by xrootd pod, at startup
WORKER_ID_FILE="/qserv/data/mysql/worker_id.txt"
while true
do
    if [ -r "$WORKER_ID_FILE" ]
    then
        WORKER=$(cat "$WORKER_ID_FILE")
        break
    fi
done

LSST_LOG_CONFIG="/config-etc/log4cxx.replication.properties"
DB_HOST="repl-db-0.qserv"
DB_PORT="3306"

CONFIG="mysql://qsreplica@${DB_HOST}:${DB_PORT}/qservReplica"
# /qserv/bin/qserv-replica-worker ${WORKER} --config=${CONFIG} --debug

# For debug purpose
while true;
do
    sleep 5
done