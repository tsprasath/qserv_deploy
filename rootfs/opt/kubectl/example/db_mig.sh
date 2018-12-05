#!/bin/sh

# Migrate database schema on all nodes

# @author Fabrice Jammes IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

PASSWORD='changeme'

echo "Migrate database schema on master"
kubectl exec master -c master -- su -l qserv -c \
    ". /qserv/stack/loadLSST.bash && \
     setup qserv_distrib -t qserv-dev && \
     qserv-smig.py -m -c mysql://root:${PASSWORD}@127.0.0.1:13306/qservMeta qmeta"

echo "Migrate database schema on all workers"
parallel --tag "kubectl exec {} -c worker -- su -l qserv -c \
    '. /qserv/stack/loadLSST.bash && \
     setup qserv_distrib -t qserv-dev && \
     qserv-smig.py -m -c mysql://root:${PASSWORD}@127.0.0.1:3306/qservw_worker wdb'" ::: $WORKER_PODS
