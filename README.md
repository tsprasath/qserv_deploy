# qserv_deploy

Qserv deployment scripts for kubernetes

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

# Run Qserv on Kubernetes

```shell
   git clone git@github.com:lsst/qserv_deploy.git
   cd qserv_deploy/k8s
   # Open a shell in a container providing kubernetes client
   ./run-kubectl.sh
```

Then, in :file:`~/.kube/env.sh`, set your container configuration (qserv images, attached volumes, ...):

```
   # Start Qserv (pods and unix services)
   ./admin/start.sh
   # Check Qserv status
   ./admin/status.sh
   # Stop Qserv
   ./admin/stop.sh
```

# Kubernetes cheat sheet

See https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/

