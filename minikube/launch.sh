set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

export MOUNT_DOT_MK=true
export QSERV_DEV=true
export QSERV_CFG_DIR="$HOME/.qserv_deploy"

mkdir -p "$QSERV_CFG_DIR"
cp "$HOME"/.kube/config "$QSERV_CFG_DIR"/kubeconfig

cp -r "$DIR"/../config.examples/minikube-ci/* "$QSERV_CFG_DIR"

"$DIR"/../qserv-deploy.sh /opt/qserv/bin/qserv-start
"$DIR"/../qserv-deploy.sh /opt/qserv/k8s/kubectl/run-multinode-tests.sh 
