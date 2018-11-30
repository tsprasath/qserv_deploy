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

mkdir -p "${CLUSTER_CONFIG_DIR}/tmp"
TMP_DIR=$(mktemp -d --tmpdir="${CLUSTER_CONFIG_DIR}/tmp" --suffix=-qserv-deploy-yaml)

# For in2p3 cluster: k8s schema cache must not be on AFS
CACHE_DIR=$(mktemp -d --tmpdir="${CLUSTER_CONFIG_DIR}/tmp" --suffix=-kube-$USER)
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

INI_FILE="${TMP_DIR}/statefulset.ini"

echo "Create kubernetes configmaps for Qserv"

CZAR="czar-0"
REPL_CTL="repl-ctl"
REPL_DB="repl-db-0"
QSERV_DOMAIN="qserv"
CZAR_DN="${CZAR}.${QSERV_DOMAIN}"

kubectl delete configmap --ignore-not-found=true config-domainnames
kubectl create configmap config-domainnames --from-literal=CZAR="$CZAR" \
    --from-literal=CZAR_DN="$CZAR_DN" \
    --from-literal=QSERV_DOMAIN="$QSERV_DOMAIN" \
    --from-literal=REPL_CTL="$REPL_CTL" \
    --from-literal=REPL_DB="$REPL_DB"

kubectl delete configmap --ignore-not-found=true config-dot-lsst
kubectl create configmap --from-file="$CONFIGMAP_DIR/dot-lsst" config-dot-lsst

kubectl delete configmap --ignore-not-found=true config-mariadb-configure
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/mariadb-configure.sh" config-mariadb-configure

kubectl delete configmap --ignore-not-found=true config-mariadb-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/start.sh" config-mariadb-start

kubectl delete configmap --ignore-not-found=true config-sql-czar
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/czar" config-sql-czar

kubectl delete configmap --ignore-not-found=true config-sql-repl
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/repl" config-sql-repl

kubectl delete configmap --ignore-not-found=true config-sql-worker
kubectl create configmap --from-file="$CONFIGMAP_DIR/init/sql/worker" config-sql-worker

kubectl delete configmap --ignore-not-found=true config-mariadb-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/mariadb/etc/my.cnf" config-mariadb-etc

kubectl delete configmap --ignore-not-found=true config-proxy-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/etc" config-proxy-etc

kubectl delete configmap --ignore-not-found=true config-proxy-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/proxy/start.sh" config-proxy-start

kubectl delete configmap --ignore-not-found=true config-repl-db-etc
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-db/etc/my.cnf" config-repl-db-etc

kubectl delete configmap --ignore-not-found=true config-repl-db-start
kubectl create configmap --from-file="$CONFIGMAP_DIR/repl-db/start.sh" config-repl-db-start

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

WORKERS_COUNT=$(echo $WORKERS | wc -w)

if [ $MINIKUBE ]; then
    INI_MINIKUBE="True"
else
    INI_MINIKUBE="False"
fi

if [ $GKE ]; then
    INI_GKE="True"
else
    INI_GKE="False"
fi

cat << EOF > "$INI_FILE"
[spec]
gke: $INI_GKE
storage_size: $STORAGE_SIZE
mem_request: $MEM_REQUEST
host_data_dir: $HOST_DATA_DIR
host_tmp_dir: $HOST_TMP_DIR
image: $CONTAINER_IMAGE
minikube: $INI_MINIKUBE
replicas: $WORKERS_COUNT
EOF

for service in "czar" "worker"
do
    YAML_TPL="${CFG_DIR}/statefulset-${service}.yaml.tpl"
    YAML_FILE="${TMP_DIR}/statefulset-${service}.yaml"
    "$DIR"/yaml-builder.py -i "$INI_FILE" -r "$RESOURCE_DIR" -t "$YAML_TPL" -o "$YAML_FILE"
    kubectl apply $CACHE_OPT -f "$YAML_FILE"
done

kubectl apply $CACHE_OPT -f "${CFG_DIR}/statefulset-repl-db.yaml"
