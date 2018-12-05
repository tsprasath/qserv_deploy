#!/bin/bash

# Wait Qserv statefulset to be in running state

# @author Fabrice Jammes SLAC/IN2P3

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

echo "Wait for Qserv statefulsets to be in running state"

GO_TPL="{{if .status.readyReplicas}}\
    .status.readyReplicas is set \
    {{end}}"

for sf in 'czar' 'qserv'
do
    echo -n "Wait for statefulset '$sf' to start first pod"
    until [ -n "$READY" ]
    do
        READY=$(kubectl get statefulset "$sf" -o go-template --template "$GO_TPL")
        sleep 2
	echo -n '.'
    done
    echo

    echo -n "Wait for statefulset '$sf' to start all pods"
    GO_TPL="{{if and (eq .spec.replicas .status.replicas) \
        (eq .status.replicas .status.readyReplicas) \
        (eq .status.currentRevision .status.updateRevision)}}true{{end}}"
    until [ -n "$STARTED" ]
    do
        STARTED=$(kubectl get statefulset "$sf" -o go-template --template "$GO_TPL")
        sleep 2
	echo -n '.'
    done
    echo
    echo "Statefulset '$sf' ready"
done
