#!/bin/sh

# Install helm on Kubernetes Cluster

# @author Fabrice Jammes, IN2P3/SLAC

set -e

DIR=$(cd "$(dirname "$0")"; pwd -P)

RBAC_YAML="${DIR}/yaml/rbac-config.yaml"

kubectl apply -f $RBAC_YAML
helm init --service-account tiller --wait
