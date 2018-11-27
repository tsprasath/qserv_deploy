# Pre-requisites

## Clone qserv_deploy on a non-afs filesystem

```shell
git clone https://github.com/lsst/qserv_deploy.git $QSERV_DEPLOY
```

## Setup configuration

```shell
export QSERV_CFG_DIR=/qserv/kubernetes/desc
mkdir -p $QSERV_CFG_DIR 
cp -r $QSERV_DEPLOY/config.examples/ccin2p3/* $QSERV_CFG_DIR 
```

Set nodes names in `/qserv/kubernetes/upper/env-infrastructure.sh`

Create gnu-parallel configuration file:
```shell
$QSERV_DEPLOY/rootfs/opt/qserv/k8s/sysadmin/create-gnuparallel-slf.sh
```

# Setup Kubernetes

Because Kerberos, scripts below must be runned directly on host, and not
inside qserv-deploy container:

```
# Create cluster
$QSERV_DEPLOY/rootfs/opt/qserv/k8s/sysadmin/kube-create.sh

# Destroy cluster
$QSERV_DEPLOY/rootfs/opt/qserv/k8s/sysadmin/kube-destroy.sh
```
