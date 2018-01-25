#!/bin/sh

# Install Weave network

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

echo "Install weave network"
KUBEVER=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$KUBEVER"

# Wait for Weave to be ready

while true
do
    READY=$(kubectl get daemonset --namespace=kube-system -l name=weave-net \
        -o go-template --template "{{range .items}}{{.status.numberReady}}{{end}}")
    if [ $READY -ge 1 ]; then
        break
    else
        echo "Wait for weave-net daemonset to be READY"
        sleep 2
    fi
done
