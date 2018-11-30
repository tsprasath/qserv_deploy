#!/bin/sh

# Configure mariadb for qserv or replication service :
# - create data directory
# - create root password
# - create qserv/repl databases and user
# - deploy scisql plugin (qserv only)

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

if [ "$HOSTNAME" = "$REPL_DB" ]; then
    MYSQL_INSTALL_DB="mysql_install_db"
else
    # Source pathes to eups packages
    . /qserv/run/etc/sysconfig/qserv
    MYSQL_INSTALL_DB="${MYSQL_DIR}/scripts/mysql_install_db --basedir=$MYSQL_DIR"
fi

# tail -f /dev/null

DATA_DIR="/qserv/data"
MYSQLD_DATA_DIR="$DATA_DIR/mysql"
MYSQLD_SOCKET="$MYSQLD_DATA_DIR/mysql.sock"
# TODO: Set password using k8s
MYSQLD_PASSWORD_ROOT="CHANGEME"
SQL_DIR="/config-sql"

MARIADB_CONF="/config-etc/my.cnf"
if [ -e "$MARIADB_CONF" ]; then
    mkdir -p /etc/mysql
    ln -sf "$MARIADB_CONF" /etc/mysql/my.cnf
fi

EXCLUDE_DIR1="lost+found"
DATA_FILES=$(find "$DATA_DIR" -mindepth 1 ! -name "$EXCLUDE_DIR1")

if [ ! "$DATA_FILES" ]
then
    echo "-- "
    echo "-- Installing mysql database files."
    ${MYSQL_INSTALL_DB} >/dev/null ||
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
    if [ "$HOSTNAME" = "$CZAR" ]; then
        INSTANCE_NAME='czar'
    elif [ "$HOSTNAME" = "$REPL_DB" ]; then
        INSTANCE_NAME='repl'
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

    if [ "$HOSTNAME" != "$REPL_DB" ]; then
        echo "-- "
        echo "-- Deploy scisql plugin"
        # WARN: SciSQL shared library (libcisql*.so) deployed by command
        # below will be removed at each container startup.
        # That's why this shared library is currently 
        # installed in mysql plugin directory at image creation.
        echo "$MYSQLD_PASSWORD_ROOT" | scisql-deploy.py --mysql-dir="$MYSQL_DIR" \
            --mysql-socket="$MYSQLD_SOCKET"
    fi

    echo "-- Stop mariadb server."
    mysqladmin -u root --password="$MYSQLD_PASSWORD_ROOT" shutdown
else
    echo "WARN: Skip mysqld initialization because of non empty $DATA_DIR:"
    ls -l "$DATA_DIR"
fi
