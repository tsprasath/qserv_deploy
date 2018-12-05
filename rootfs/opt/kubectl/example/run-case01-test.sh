#!/bin/bash

# Launch Qserv multinode tests on Swarm cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

# Build CSS input data
i=1
for node in $WORKERS;
do
    CSS_INFO="${CSS_INFO}CREATE NODE worker${i} type=worker port=5012 \
    host=worker-${i}.qserv; "
    i=$((i+1))
done

kubectl exec master -c proxy -- su qserv -l -c ". /qserv/stack/loadLSST.bash && \
    setup qserv_distrib -t qserv-dev && \
    echo \"$CSS_INFO\" | qserv-admin.py -c mysql://qsmaster@127.0.0.1:3306/qservCssData && \
    qserv-check-integration.py --case=01 --load -V DEBUG"

