# qserv_deploy

Qserv deployment scripts for kubernetes

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

This script is in 3 parts:
* VM image creation
* Cluster provisioning on OpenStack
* K8s cluster creation and Qserv deployment (and tests)

You can execute each parts indenpendently (eg. if you already have an OpenStack cluster running)

# Prequisites

You will need a openrc.sh file with your openstack credentials.

```shell
   git clone https://github.com/lsst/qserv_deploy.git
   # Create a directory to store your cluster(s) configuration
   export CLUSTER_CONFIG_DIR=$HOME/.lsst/qserv-cluster/<cluster-name>
   mkdir -p $CLUSTER_CONFIG_DIR
   cp <openstack-rc-file> $CLUSTER_CONFIG_DIR/os-openrc.sh
```
If you already have a cluster config directory, you only need to export the `CLUSTER_CONFIG_DIR` var.

# Usages

## Creating an image

You can create an OpenStack vm image for the cluster nodes.

```shell
   # Copy image.conf from an example and edit it to suit your needs
   cp config.examples/<example-cluster>/image.conf $CLUSTER_CONFIG_DIR/
   cd openstack
   ./provision-install-test.sh -c
```

## Spawning a cluster

You can spawn a cluster of machines on OpenStack. This script will:
* Create a ssh bastion node with an external IP
* Create a k8s master (orchestra)
* Create n+1 k8s workers (including n qserv workers and a qserv master)
* Update the /etc/hosts on all machines
* Create the cluster configuration files in your `CLUSTER_CONFIG_DIR` directory

```shell
   # Copy terraform.tfvars from an example and edit it to suit your needs
   cp config.examples/<example-cluster>/terraform.tfvars $CLUSTER_CONFIG_DIR/
   cd openstack
   ./provision-install-test.sh -p
```

## Installing kubernetes and running Qserv

This will install kubernetes and deploy Qserv on the cluster, then run integrations tests.

```shell
   cd openstack
   ./provision-install-test.sh -k
```

## Deleting your cluster

This will delete your cluster but keep the VM image:

```shell
   cd openstack
   ./provision-install-test.sh -d
```

# Development

## Run Qserv on Kubernetes

```shell
   git clone https://github.com/lsst/qserv_deploy.git
   cd qserv_deploy/k8s
   # Open a shell in a container providing kubernetes client
   ./run-kubectl.sh
```

Then, in :file:`~/.lsst/qserv-cluster/env.sh`, set your container configuration (qserv images, attached volumes, ...):

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
