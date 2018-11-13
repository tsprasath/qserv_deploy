#!/bin/sh

# Start cmsd and xrootd inside pod
# Launch as qserv user

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
# set -x

# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

CONFIG_DIR="/config-etc"
XROOTD_CONFIG="$CONFIG_DIR/xrootd.cf"
XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"
DATA_DIR="/qserv/data"
MARIADB_LOCK="$DATA_DIR/mariadb-cfg.lock"
MYSQLD_DATA_DIR="$DATA_DIR/mysql"
MYSQLD_SOCKET="$MYSQLD_DATA_DIR/mysql.sock"

# Wait for mysql to be configured and started
while true; do
    if mysql --socket "$MYSQLD_SOCKET" --user="$MYSQLD_USER_QSERV"  --skip-column-names \
        -e "SELECT CONCAT('Mariadb is up: ', version())"
    then
        if [ -f $MARIADB_LOCK ]
        then
            echo "Wait for MySQL to be configured"
        else
            break
        fi
    else
        echo "Wait for MySQL startup"
    fi
    sleep 2
done

# INSTANCE_NAME is required by xrdssi plugin to
# choose which type of queries to launch against metadata
if [ "$HOSTNAME" = "$CZAR" ]; then
    INSTANCE_NAME='master'
else
    INSTANCE_NAME='worker'

    MLOCK_AMOUNT=$(ulimit -l)
    echo "Limit for locked-in memory: $MLOCK_AMOUNT"

    # Wait for xrootd master reachability
    until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${CZAR_DN}/1094"
    do
        echo "waiting for xrootd master (${CZAR_DN})..."
        sleep 2
    done
fi

# When at least one of the current pod's containers
# readiness health check pass, then dns name resolve.
until ping -c 1 ${HOSTNAME}.${QSERV_DOMAIN}; do
  echo "waiting for DNS (${HOSTNAME}.${QSERV_DOMAIN})..."
  sleep 2
done

# Start cmsd and xrootd
#
PROCESSES="cmsd xrootd"

for p in $PROCESSES;
do
    "${p}" -c "$XROOTD_CONFIG" -l @libXrdSsiLog.so -n "$INSTANCE_NAME" -I v4 -+xrdssi "$XRDSSI_CONFIG" &
done

# Monitor cmsd and xrootd
PERIOD_SECONDS=5
while true;
do
    sleep "$PERIOD_SECONDS"
    for p in $PROCESSES;
    do
        if ! pidof "$p" > /dev/null ; then
            echo "ERROR: ${p} not running, exiting"
            exit 1
        fi
    done
done
