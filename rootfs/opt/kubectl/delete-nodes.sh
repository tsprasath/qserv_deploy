#!/bin/sh

# Destroy Kubernetes nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

# Delete worker nodes before master nodes to avoid virtual network inconsistency
WORKER_GO_TPL='{{range .items}}{{$x := index .metadata.labels "node-role.kubernetes.io/master"}}{{ if not (eq (printf "%T" $x) "string") }}{{printf "%v " .metadata.name}}{{end}}{{end}}'
WORKER_NODES=$(kubectl get nodes -o go-template="$WORKER_GO_TPL")
if [ "$WORKER_NODES" ]
then
    parallel "kubectl drain '{}' --delete-local-data --force --ignore-daemonsets && \
        kubectl delete node '{}'" ::: $WORKER_NODES
fi

MASTER_GO_TPL='{{range .items}}{{$x := index .metadata.labels "node-role.kubernetes.io/master"}}{{ if (eq (printf "%T" $x) "string") }}{{printf "%v " .metadata.name}}{{end}}{{end}}'
MASTER_NODES=$(kubectl get nodes -o go-template="$MASTER_GO_TPL")
if [ "$MASTER_NODES" ]
then
    parallel "kubectl drain '{}' --delete-local-data --force --ignore-daemonsets && \
        kubectl delete node '{}'" ::: $MASTER_NODES
fi
