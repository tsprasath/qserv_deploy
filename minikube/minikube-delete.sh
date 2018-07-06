set -e
set -x

MINIKUBE_BIN=/usr/local/bin/minikube

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir -p $HOME/.kube
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

sudo -E "$MINIKUBE_BIN" stop
sudo -E "$MINIKUBE_BIN" delete || echo "WARN: unable to delete minikube"
sudo rm -rf /etc/kubernetes
sudo rm -rf /data/minikube
sudo rm -rf $HOME/.kube
sudo rm -rf $HOME/.minikube
