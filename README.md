# qserv_deploy

Fully automated procedure to spawn a Qserv cluster from scratch on Openstack.

[![Build
Status](https://travis-ci.org/lsst/qserv_deploy.svg?branch=master)](https://travis-ci.org/lsst/qserv_deploy)

# Prequisites

* Install Docker for your distribution (https://docs.docker.com/install/)

* Create an ssh key, without password
```shell
ssh-keygen  -f ~/.ssh/id_rsa_openstack
```
* Create a cluster configuration directory which contains all informations to manage you Qserv cloud instance.

```shell
   git clone https://github.com/lsst/qserv_deploy.git
   
   # Set cloud name, 'sbg' and 'petasky' are supported
   export CLOUD=petasky
   
   # Create a directory to store your cluster(s) configuration
   export QSERV_CFG_DIR="$HOME/.lsst/qserv-cluster/$CLOUD"
   mkdir -p $QSERV_CFG_DIR
   cp -r "qserv_deploy/config.examples/$CLOUD"/* "$QSERV_CFG_DIR"
   
   # Edit openstack credentials in file below
   vi "$QSERV_CFG_DIR/os-openrc.sh"
```

It is also possible to use an existing cluster configuration directory, by exporting the `QSERV_CFG_DIR` variable.

# Usages

Start the tool by running `./qserv-deploy.sh`

In the container, all commands are prefixed with qserv-***
Your working directory is /qserv-deploy with your cluster configuration mounted in config folder

## Spawn a cluster

Spawn a cluster of machines on OpenStack. This script will:
* Create a ssh bastion node with a external public IP adress
* Create a k8s master (orchestra)
* Create n+1 k8s workers (including n qserv workers and a qserv master)
* Update the /etc/hosts on all machines
* Create additional cluster configuration files in your `QSERV_CFG_DIR` directory (ssh configuration, name of the nodes, ...)

```shell
   # Edit file below (optional, advanced users)
   vi config/terraform.tfvars
   
   # Spawn the cluster
   qserv-deploy -p
```

## Install Kubernetes, Qserv and run integration tests

This will install kubernetes and deploy Qserv on the cluster, then run integrations tests.

```shell
   qserv-deploy -k
```

## Deleting your cluster

This will delete your cluster but keep the virtual machine image for Kubernetes nodes:

```shell
   qserv-deploy -d
```

## Create a Kubernetes node image (optional, advanced users)

By default, the tool use an image provided by project maintainers.
Create an OpenStack virtual machine image for the cluster nodes.

```shell
   # Edit file below if needed
   vi config/image.conf
   qserv-deploy -c
```

# Commands list

* `qserv-deploy` : Qserv cluster provisionning and installation
* `qserv-start` : Start Qserv on the cluster
* `qserv-status` : Show Qserv running status
* `qserv-stop` : Stop Qserv

# Development

## Advanced configuration

Edit the cluster configuration in `config` directory

Advanced kubernetes scripts are available in `kubectl`
Advanced cluster administration scripts are available in `sysadmin`

## Run Qserv on Kubernetes

```shell
    # To access Kubernetes master with kubectl
    # Open an ssh tunnel from localhost:6443 to master 6443 port
    ssh-tunnel
    # Use kubectl
    kubectl get pods
```

## Access Kubernetes nodes via ssh

```shell
   # Check node names in 
   grep -w Host config/ssh_config
   
   # ssh a node
   ssh -F config/ssh_config <node_name>
```

# Kubernetes cheat sheet

See https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/
