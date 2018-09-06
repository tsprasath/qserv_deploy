#!/bin/sh

# Launch Qserv pods on Kubernetes cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

CLUSTER_CONFIG_DIR="${CLUSTER_CONFIG_DIR:-/qserv-deploy/config}"
. "$CLUSTER_CONFIG_DIR/env.sh"

CFG_DIR="${DIR}/yaml"
RESOURCE_DIR="${DIR}/resource"
CONFIGMAP_DIR="${DIR}/configmap"
TMP_DIR=$(mktemp -d --suffix=-qserv-deploy-yaml)

# For in2p3 cluster: k8s schema cache must not be on AFS
CACHE_DIR=$(mktemp -d --suffix=-kube-$USER)
CACHE_OPT="--cache-dir=$CACHE_DIR/schema"

usage() {
  cat << EOD

  Usage: $(basename "$0") [options]

  Available options:
    -h          this message

  Launch Qserv service and pods on Kubernetes

EOD
}

# get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
    usage
    exit 2
fi

YAML_TPL="${CFG_DIR}/statefulset.yaml.tpl"
YAML_FILE="${TMP_DIR}/statefulset.yaml"
INI_FILE="${TMP_DIR}/statefulset.ini"

echo "Create kubernetes configmaps for Qserv"

QSERV_MASTER="qserv-0"
QSERV_DOMAIN="qserv"
QSERV_MASTER_DN="${QSERV_MASTER}.${QSERV_DOMAIN}"

kubectl delete configmap --ignore-not-found=true config-master
kubectl create configmap config-master --from-literal=qserv_master="$QSERV_MASTER" \
    --from-literal=qserv_domain="$QSERV_DOMAIN" \
    --from-literal=qserv_master_dn="$QSERV_MASTER_DN"

kubectl delete configmap --ignore-not-found=true config-dot-lsst
kubectl create configmap --from-file="$CONFIGMAP_DIR/dot-lsst" config-dot-lsst

kubectl delete configmap --ignore-not-found=true config-mariadb-configure
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/mariadb-configure.sh" config-mariadb-configure

kubectl delete configmap --ignore-not-found=true config-mariadb-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/start.sh" config-mariadb-start

kubectl delete configmap --ignore-not-found=true config-sql-master
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/master" config-sql-master

kubectl delete configmap --ignore-not-found=true config-sql-worker
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/worker" config-sql-worker

kubectl delete configmap --ignore-not-found=true config-mariadb-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/etc/my.cnf" config-mariadb-etc

kubectl delete configmap --ignore-not-found=true config-proxy-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/etc" config-proxy-etc

kubectl delete configmap --ignore-not-found=true config-proxy-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/start.sh" config-proxy-start

kubectl delete configmap --ignore-not-found=true config-proxy-probe
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/probe.sh" config-proxy-probe

kubectl delete configmap --ignore-not-found=true config-wmgr-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/etc" config-wmgr-etc 

kubectl delete configmap --ignore-not-found=true config-wmgr-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/wmgr/start.sh" config-wmgr-start

kubectl delete configmap --ignore-not-found=true config-xrootd-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/start.sh" config-xrootd-start

kubectl delete configmap --ignore-not-found=true config-xrootd-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/xrootd/etc" config-xrootd-etc

echo "Create kubernetes secrets for Qserv"
kubectl delete secret --ignore-not-found=true secret-wmgr
kubectl create secret generic secret-wmgr \
        --from-file="$CONFIGMAP_DIR/wmgr/wmgr.secret"


echo "Create headless service for Qserv"
kubectl apply $CACHE_OPT -f ${CFG_DIR}/qserv-headless-service.yaml

echo "Create nodeport service for Qserv"
kubectl apply $CACHE_OPT -f ${CFG_DIR}/qserv-nodeport-service.yaml

echo "Create kubernetes pod for Qserv statefulset"

REPLICAS=$(echo $WORKERS $MASTER | wc -w)

if [ "$MASTER" = "-MK-" ]; then
    MINIKUBE="True"
else
    MINIKUBE="False"
fi

cat << EOF > "$INI_FILE"
[spec]
host_data_dir: $HOST_DATA_DIR
host_tmp_dir: $HOST_TMP_DIR
image: $CONTAINER_IMAGE
minikube: $MINIKUBE
replicas: $REPLICAS
EOF

"$DIR"/yaml-builder.py -i "$INI_FILE" -r "$RESOURCE_DIR" -t "$YAML_TPL" -o "$YAML_FILE"

kubectl apply $CACHE_OPT -f "$YAML_FILE"
