#!/bin/sh

# Start cmsd and xrootd inside pod
# Launch be qserv user

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x


# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

MARIADB_CFG_LOCK="/qserv/data/mariadb-cfg.lock"

# Wait for mysql to be configured and started
while true; do
    if mysql --socket "$MYSQLD_SOCK" --user="$MYSQLD_USER_QSERV"  --skip-column-names \
        -e "SELECT CONCAT('Mariadb is up: ', version())"
    then
        if [ -f $MARIADB_CFG_LOCK ]
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

# Start xrootd
#
CONFIG_DIR="/config-etc"
XROOTD_CONFIG="$CONFIG_DIR/xrootd.cf"
XRDSSI_CONFIG="$CONFIG_DIR/xrdssi.cf"

cmsd -c "$XROOTD_CONFIG" -l @libXrdSsiLog.so -n "$NODE_TYPE" -I v4 -+xrdssi "$XRDSSI_CONFIG" &
xrootd -c  "$XROOTD_CONFIG" -l @libXrdSsiLog.so -n "$NODE_TYPE" -I v4 -+xrdssi "$XRDSSI_CONFIG"
