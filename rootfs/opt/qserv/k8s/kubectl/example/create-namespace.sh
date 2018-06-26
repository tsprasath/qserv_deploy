#!/bin/sh

# Create a namespace and set it as default one 

# @author Fabrice Jammes IN2P3

set -e

NAMESPACE=desc
kubectl create namespace "$NAMESPACE"
kubectl config set-context $(kubectl config current-context) --namespace="$NAMESPACE"
