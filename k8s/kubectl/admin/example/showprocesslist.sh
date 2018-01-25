#!/bin/bash

# Help removing qserv database 
# WARN: do not currently remove database but only metadata 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DB=mysql

kubectl exec master -c master -- \
    bash -c ". /qserv/stack/loadLSST.bash && \
    setup mariadbclient && \
    mysql -h 127.0.0.1 -P 4040 \
    --user=root --password=changeme $DB \
    -e \"SHOW PROCESSLIST;\""
