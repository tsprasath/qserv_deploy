#!/bin/sh

# Install Weave network

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

counter=0
while ! kubectl get componentstatuses
do
    if [ "$counter" -lt 10 ]
    then
        echo "Wait for master to be up"
        sleep 1
    else
        echo "ERROR: master startup failed"
        exit 1 
    fi
    counter=$((counter+1))
done

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
