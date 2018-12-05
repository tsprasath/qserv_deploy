# qserv_deploy on gke

Automated procedure to spawn a Qserv cluster.

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

# Prequisites

* Create a cluster configuration directory:

```shell
   git clone https://github.com/lsst/qserv_deploy.git

   # Create a directory to store your cluster(s) configuration
   export QSERV_CFG_DIR="$HOME/.qserv/"
   mkdir -p $QSERV_CFG_DIR

   cp -r qserv_deploy/config.examples/gke/* "$QSERV_CFG_DIR"
```

It is also possible to use an existing cluster configuration directory, by exporting the `QSERV_CFG_DIR` variable.

# Usage

Start the tool by running `./qserv-deploy.sh`

Then get kubeconfig for your gke cluster, following example below:

```
gcloud auth login
# Example:
# PROJECT=neural-theory-215601
PROJECT=<project>
# Example:
# CLUSTER=qserv-cluster
CLUSTER=<cluster>
gcloud config set project "$PROJECT"
gcloud container clusters resize "$CLUSTER" --region us-central1-a --size=31
gcloud container clusters get-credentials "$CLUSTER" --zone us-central1-a --project "$PROJECT"
```

In the container, all commands are prefixed with "qserv-"


Your working directory is /qserv-deploy with your cluster configuration mounted in config folder

## Install Qserv

# Commands list

* `qserv-start`: Start Qserv on the cluster (and create all pods)
* `qserv-status`: Show Qserv running status
* `qserv-stop`: Stop Qserv (and remove all pods)
* `/opt/kubectl/run-multinode-tests.sh`: Run integration tests

## Clean up storage

```
# WARN: this will delete all persistent volumes and volumes claims in your project
kubectl delete pvc --all
kubectl delete pv --all
```
