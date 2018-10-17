#!/bin/sh

# Create czar and worker node pools for GKE cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"

gcloud --quiet container node-pools delete default-pool --zone $ZONE --cluster $CLUSTER

$DIR/create-nodepool.sh "pool-czar" "$MTYPE_CZAR" "$SIZE_CZAR"
$DIR/create-nodepool.sh "pool-worker" "$MTYPE_WORKER" "$SIZE_WORKER"
