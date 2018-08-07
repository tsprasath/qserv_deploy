#!/bin/bash

# Wait Qserv statefulset to be in running state

# @author Fabrice Jammes SLAC/IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

echo "Wait for Qserv statefulset to be in running state"

GO_TPL="{{if .status.readyReplicas}}\
    .status.readyReplicas is set \
    {{end}}"

until [ -n "$READY" ]
do
    echo "Wait for statefulset to start first pod"
    READY=$(kubectl get statefulset qserv -o go-template --template "$GO_TPL")
    sleep 1
done

GO_TPL="{{if and (eq .spec.replicas .status.replicas) \
    (eq .status.replicas .status.readyReplicas) \
    (eq .status.currentRevision .status.updateRevision)}}true{{end}}"
until [ -n "$STARTED" ]
do
    echo "Wait for statefulset to start all pods"
    STARTED=$(kubectl get statefulset qserv -o go-template --template "$GO_TPL")
    sleep 2
done
