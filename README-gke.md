# qserv_deploy on gke

Automated procedure to spawn a Qserv cluster.

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

# Prequisites

* Create a cluster configuration directory which contains a kubeconfig file.

```shell
   git clone https://github.com/lsst/qserv_deploy.git

   # Create a directory to store your cluster(s) configuration
   export QSERV_CFG_DIR="$HOME/.qserv/"
   mkdir -p $QSERV_CFG_DIR

   # Please ask support for how to fine tune files below
   # (This files should be deprecated in near future)
   cp -r "qserv_deploy/config.examples/petasky* "$QSERV_CFG_DIR"

   cp <kubeconfig> $QSERV_CFG_DIR

```

It is also possible to use an existing cluster configuration directory, by exporting the `QSERV_CFG_DIR` variable.

# Usage

Start the tool by running `./qserv-deploy.sh`

In the container, all commands are prefixed with qserv-***
Your working directory is /qserv-deploy with your cluster configuration mounted in config folder

## Install Qserv

# Commands list

* `qserv-start`: Start Qserv on the cluster
* `qserv-status`: Show Qserv running status
* `qserv-stop`: Stop Qserv
* `/opt/qserv/k8s/kubectl/run-multinode-tests.sh`: Run integration tests
