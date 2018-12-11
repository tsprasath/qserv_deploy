#!/bin/bash

# Start Qserv replication worker service inside pod

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

REPL_DB_HOST="repl-db-0.qserv"
REPL_DB_PORT="3306"
REPL_DB_USER="qsreplica"
REPL_DB="qservReplica"
DATA_DIR="/qserv/data"
MYSQLD_DATA_DIR="$DATA_DIR/mysql"
MYSQLD_SOCKET="$MYSQLD_DATA_DIR/mysql.sock"
MYSQLD_USER_QSERV="qsmaster"


# Wait for local mysql to be started
while true; do
    if mysql --socket "$MYSQLD_SOCKET" --user="$MYSQLD_USER_QSERV"  --skip-column-names \
        -e "SELECT CONCAT('Mariadb is up: ', version())"
    then
        break
    else
        echo "Wait for MySQL startup"
    fi
    sleep 2
done

 # Retrieve worker id
WORKER=$(mysql --socket "$MYSQLD_SOCKET" --batch \
    --skip-column-names --user="$MYSQLD_USER_QSERV" -e "SELECT id FROM qservw_worker.Id;")
if [ -z "$WORKER" ]; then
    >&2 echo "ERROR: unable to retrieve worker id for $HOSTNAME"
    exit 1 
fi

# Wait for repl-db started
while true; do
    if mysql  --host="$REPL_DB_HOST" --port="$REPL_DB_PORT" --user="$REPL_DB_USER"  --skip-column-names \
        "${REPL_DB}" -e "SELECT CONCAT('Mariadb is up: ', version())"
    then
        break
    else
        echo "Wait for repl-db startup"
    fi
    sleep 2
done

export LSST_LOG_CONFIG="/config-etc/log4cxx.replication.properties"

CONFIG="mysql://${REPL_DB_USER}@${REPL_DB_HOST}:${REPL_DB_PORT}/${REPL_DB}"
qserv-replica-worker ${WORKER} --config=${CONFIG}

# For debug purpose
#while true;
#do
#    sleep 5
#done
