#!/bin/sh

# Configure mariadb:
# - create data directory
# - create root password
# - create qserv databases and user
# - deploy scisql plugin

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

# tail -f /dev/null

DATA_DIR="/qserv/data"
MARIADB_LOCK="$DATA_DIR/mariadb-cfg.lock"
MYSQLD_DATA_DIR="$DATA_DIR/mysql"
MYSQLD_SOCKET="$MYSQLD_DATA_DIR/mysql.sock"
# TODO: Set password using k8s
MYSQLD_PASSWORD_ROOT="CHANGEME"
SQL_DIR="/config-sql"

MARIADB_CONF="/config-etc/my.cnf"
if [ -e "$MARIADB_CONF" ]; then
    ln -sf "$MARIADB_CONF" /etc/my.cnf
fi

# Make timezone adjustments (if requested)
# TODO: set tz using k8s: http://cloudgeekz.com/1170/howto-timezone-for-kubernetes-pods.html
if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then

    # These files have to be write-enabled for the current user ('qserv')

    echo ${CONTAINER_TIMEZONE} >/etc/timezone && \
    cp /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata

    echo "Container timezone set to: $CONTAINER_TIMEZONE"
else
    echo "Container timezone not modified"
fi

EXCLUDE_DIR1="lost+found"
DATA_FILES=$(find "$DATA_DIR" -mindepth 1 ! -name "$EXCLUDE_DIR1")

if [ ! "$DATA_FILES" ]
then
    touch "$MARIADB_LOCK"
    echo "-- "
    echo "-- Installing mysql database files."
    ${MYSQL_DIR}/scripts/mysql_install_db --basedir="${MYSQL_DIR}" >/dev/null ||
        {
            echo "ERROR : mysql_install_db failed, exiting"
            exit 1
        }

    echo "-- "
    echo "-- Start mariadb server."
    mysqld &
    sleep 5

    echo "-- "
    echo "-- Change mariadb root password."
    mysqladmin -u root password "$MYSQLD_PASSWORD_ROOT"

    echo "-- "
    echo "-- Initializing Qserv database"
    if [ "$HOSTNAME" = "$QSERV_MASTER" ]; then
        INSTANCE_NAME='master'
    else
        INSTANCE_NAME='worker'
    fi
    for file_name in "${SQL_DIR}/${INSTANCE_NAME}"/*; do
        echo "-- Loading ${file_name} in MySQL"
        if mysql -vvv --user="root" --password="${MYSQLD_PASSWORD_ROOT}" \
            < "${file_name}"
        then
            echo "-- -> success"
        else
            echo "-- -> error"
            exit 1
        fi
    done

    echo "-- "
    echo "-- Deploy scisql plugin"
	# WARN: SciSQL shared library (libcisql*.so) deployed by command
	# below will be removed at each container startup.
    # That's why this shared library is currently 
	# installed in mysql plugin directory at image creation.
    echo "$MYSQLD_PASSWORD_ROOT" | scisql-deploy.py --mysql-dir="$MYSQL_DIR" \
        --mysql-socket="$MYSQLD_SOCKET"

    echo "-- Stop mariadb server."
    mysqladmin -u root --password="$MYSQLD_PASSWORD_ROOT" shutdown
    rm "$MARIADB_LOCK"
else
    echo "WARN: Skip mysqld initialization because of non empty $DATA_DIR:"
    ls -l "$DATA_DIR"
fi
