DIR=$(cd "$(dirname "$0")"; pwd -P)

export QSERV_CFG_DIR="$HOME/.qserv_deploy"
mkdir -p "$QSERV_CFG_DIR"
cp $HOME/.kube/config "$QSERV_CFG_DIR"/kubeconfig

cp -r $DIR/../config.examples/minikube-ci/* "$QSERV_CFG_DIR"

$DIR/../qserv-deploy.sh
