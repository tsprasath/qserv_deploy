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

while true
do
    WORKER=$(mysql --socket /qserv/data/mysql/mysql.sock --batch \
    --skip-column-names --user=qsmaster -e "SELECT id FROM qservw_worker.Id;")
    if [ -n "$WORKER" ]; then
        break
    fi
done

# Start workers on all nodes

LSST_LOG_CONFIG="/config-etc/log4cxx.replication.properties"

DB_HOST="repl-db-0"
DB_PORT="3306"

CONFIG="mysql://qsreplica@${DB_HOST}:${DB_PORT}/qservReplica"
/qserv/bin/qserv-replica-worker ${WORKER} --config=${CONFIG} --debug

