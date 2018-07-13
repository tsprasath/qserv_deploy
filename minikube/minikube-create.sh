set -e
set -x

MINIKUBE_BIN="/usr/local/bin/minikube"
KUBECTL_BIN="/usr/local/bin/kubectl"

export CHANGE_MINIKUBE_NONE_USER=true
export MINIKUBE_HOME=$HOME
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_WANTUPDATENOTIFICATION=false
export KUBECONFIG=$HOME/.kube/config

mkdir -p $HOME/.kube
touch $HOME/.kube/config

# Download kubectl, which is a requirement for using minikube.
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -Lo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl "$KUBECTL_BIN"

# Download minikube.
MINIKUBE_VERSION="v0.25.2"
curl -Lo /tmp/minikube https://storage.googleapis.com/minikube/releases/"$MINIKUBE_VERSION"/minikube-linux-amd64 &&
chmod +x /tmp/minikube
sudo mv /tmp/minikube "$MINIKUBE_BIN"

sudo -E "$MINIKUBE_BIN" start --vm-driver=none --kubernetes-version=v1.9.0
# Fix the kubectl context, as it's often stale.
"$MINIKUBE_BIN" update-context

# this for loop waits until kubectl can access the api server that Minikube has created
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
until "$KUBECTL_BIN" get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"
  do sleep 1
done
