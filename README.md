# qserv_deploy

Qserv deployment scripts for kubernetes

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

This script is in 3 parts:
* VM image creation
* Cluster provisioning on OpenStack
* K8s cluster creation and Qserv deployment (and tests)

Each parts can be runned indenpendently (eg. if you already have an OpenStack cluster running)

# Prequisites

* Create an ssh key, without password
```shell
ssh-keygen  -f ~/.ssh/id_rsa_openstack
```

* Install terraform

See https://www.terraform.io/intro/getting-started/install.html


* Create a cluster configuration directory which contains all informations to manage you Qserv cloud instance.

```shell
   git clone https://github.com/lsst/qserv_deploy.git
   
   # Set cloud name, 'sbg' and 'petasky' are supported
   export CLOUD=petasky
   
   # Create a directory to store your cluster(s) configuration
   export CLUSTER_CONFIG_DIR="$HOME/.lsst/qserv-cluster/$CLOUD"
   mkdir -p $CLUSTER_CONFIG_DIR
   cp -r "qserv_deploy/config.$CLOUD"/* "$CLUSTER_CONFIG_DIR"
   
   # Edit openstack credentials in file below
   vi $CLUSTER_CONFIG_DIR/os-openrc.sh
   
   # Go inside project
   cd qserv_deploy/openstack
```

It is also possible to use an existing cluster configuration directory, by exporting the `CLUSTER_CONFIG_DIR` variable.

# Usages

## Create an image (optional, advanced users)

By default, the tool use an image provided by project maintainers.
Create an OpenStack vm image for the cluster nodes.

```shell
   # Edit file below if needed
   vi $CLUSTER_CONFIG_DIR/image.conf
   ./provision-install-test.sh -c
```

## Spawn a cluster

Spawn a cluster of machines on OpenStack. This script will:
* Create a ssh bastion node with a external public IP adress
* Create a k8s master (orchestra)
* Create n+1 k8s workers (including n qserv workers and a qserv master)
* Update the /etc/hosts on all machines
* Create additional cluster configuration files in your `CLUSTER_CONFIG_DIR` directory (ssh configuration, name of the nodes, ...)

```shell
   # Edit file below if needed
   vi $CLUSTER_CONFIG_DIR/image.conf
   ./provision-install-test.sh -p
```

## Install kubernetes, Qserv and run integration tests

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
   # An ssh tunnel has been created by above command in order to grant access to k8s master on port 6443
   cd qserv_deploy/k8s
   # Open a shell in a container providing kubernetes client
   ./run-kubectl.sh
   # Kubernetes access is now enabled
   kubectl get pods
```

Then, set your container configuration (qserv images, attached volumes, ...) in :file:`$CLUSTER_CONFIG_DIR/env.sh`, :

```shell
   # Start Qserv (pods and unix services)
   ./admin/start.sh
   # Check Qserv status
   ./admin/status.sh
   # Stop Qserv
   ./admin/stop.sh
```

## Access kubernetes nodes via ssh

```shell
   # Check node names in 
   grep -w Host $CLUSTER_CONFIG_DIR/ssh_config
   
   # ssh a node
   ssh -F $CLUSTER_CONFIG_DIR/ssh_config <node_name>
```

# Kubernetes cheat sheet

See https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/
