#!/bin/bash

# Launch Qserv multinode tests on Swarm cluster

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

# Build CSS input data
i=0
for node in $WORKERS;
do
    CSS_INFO="${CSS_INFO}CREATE NODE worker${i} type=worker port=5012 \
    host=qserv-${i}.qserv; "
    i=$((i+1))
done

kubectl exec czar-0 -c proxy -- su qserv -l -c ". /qserv/stack/loadLSST.bash && \
    setup qserv_distrib -t qserv-dev && \
    echo \"$CSS_INFO\" | qserv-admin.py -c mysql://qsmaster@127.0.0.1:3306/qservCssData && \
    qserv-test-integration.py -V DEBUG"

