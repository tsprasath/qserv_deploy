#!/bin/bash

# This file is part of qserv.
#
# Developed for the LSST Data Management System.
# This product includes software developed by the LSST Project
# (https://www.lsst.org).
# See the COPYRIGHT file at the top-level directory of this distribution
# for details of code ownership.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Start services on all nodes

set -e

# Load parameters of the setup into the corresponding environment
# variables

# Start master controller

echo "[${HOSTNAME}] starting controller"
OPT_MALLOC_CONF=
OPT_LD_PRELOAD=
if [ ! -z "${USE_JEMALLOC}" ]; then
    OPT_MALLOC_CONF=prof_leak:true,lg_prof_interval:31,lg_prof_sample:22,prof_final:true
    OPT_LD_PRELOAD=/qserv/lib/libjemalloc.so
fi

DB_HOST="repl-db-0.qserv"
DB_PORT="3306"
CONFIG="mysql://qsreplica@:${DB_HOST}:${DB_PORT}/qservReplica"

# Base directory of the replication system on both master and worker nodes
REPLICATION_DATA_DIR="/qserv/replication"

# Configuration files of the Replication system's processes on both master
# and the worker nodes.   
CONFIG_DIR="${REPLICATION_DATA_DIR}/config"

# Work directory for the applications. It can be used by applications
# to store core files, as well as various debug information.
WORK_DIR="${REPLICATION_DATA_DIR}/work"
PARAMETERS="--worker-evict-timeout=3600 --health-probe-interval=120 --replication-interval=1200"

# Configuration file of the Replication system's processes on both master
# and the worker nodes.   
LSST_LOG_CONFIG="${CONFIG_DIR}/log4cxx.replication.properties"

cd ${WORK_DIR}
MALLOC_CONF=${OPT_MALLOC_CONF} LD_PRELOAD=${OPT_LD_PRELOAD} \
/qserv/bin/qserv-replica-master ${PARAMETERS} --config=${CONFIG} --debug"
