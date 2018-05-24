#!/bin/sh

# Destroy Kubernetes nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

NODES=$(kubectl get nodes -o go-template --template \
    '{{range .items}}{{.metadata.name}} {{end}}')

parallel "kubectl drain '{}' --delete-local-data --force --ignore-daemonsets && \
    kubectl delete node '{}'" ::: $NODES

