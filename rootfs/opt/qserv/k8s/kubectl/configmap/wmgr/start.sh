#!/bin/sh
#
# qserv-wmgr   This script starts Qserv worker management service.
#
# description: start and stop qserv worker management service

# Description: qserv-wmgr is the Qserv worker management service \
#              It provides RESTful HTTP interface which is a single \
#              end-point for all worker communication and control.

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CONFIG="/etc/wmgr.cnf"
cp "/config-etc/wmgr.cnf" "$CONFIG"
sed -i "s/<ENV_QSERV_MASTER_DN>/${QSERV_MASTER_DN}/" "$CONFIG"

su qserv -c "
# Source functions library.
. /qserv/run/etc/init.d/qserv-functions

# Source pathes to eups packages
. /qserv/run/etc/sysconfig/qserv

# Check variables which are not controlled by application
NAME="qserv-wmgr"
check_writable \${NAME} "QSERV_RUN_DIR"

# Disabling buffering in python in order to enable "real-time" logging.
export PYTHONUNBUFFERED=1

\${PYTHON} qservWmgr.py -c ${CONFIG} -v"
