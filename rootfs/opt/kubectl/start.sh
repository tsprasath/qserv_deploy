#!/bin/sh

# Launch Qserv pods on Kubernetes cluster

# @author  Fabrice Jammes, IN2P3/SLAC

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

. "$QSERV_CFG_DIR/env.sh"

CFG_DIR="${DIR}/yaml"
RESOURCE_DIR="${DIR}/resource"
CONFIGMAP_DIR="${DIR}/configmap"

mkdir -p "${QSERV_CFG_DIR}/tmp"
TMP_DIR=$(mktemp -d --tmpdir="${QSERV_CFG_DIR}/tmp" --suffix=-qserv-deploy-yaml)

# For in2p3 cluster: k8s schema cache must not be on AFS
CACHE_DIR=$(mktemp -d --tmpdir="${QSERV_CFG_DIR}/tmp" --suffix=-kube-$USER)
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

"$DIR"/update-configmaps.sh

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

kubectl apply $CACHE_OPT -f "${CFG_DIR}/statefulset-repl-db.yaml"
for service in "czar" "worker" "repl-ctl"
do
    YAML_TPL="${CFG_DIR}/statefulset-${service}.tpl.yaml"
    YAML_FILE="${TMP_DIR}/statefulset-${service}.yaml"
    "$DIR"/yaml-builder.py -i "$INI_FILE" -r "$RESOURCE_DIR" -t "$YAML_TPL" -o "$YAML_FILE"
    kubectl apply $CACHE_OPT -f "$YAML_FILE"
done

# TODO study deployment instead of stateful set for repl-ctl
# kubectl apply $CACHE_OPT -f "${CFG_DIR}/repl-ctl-service.yaml"
