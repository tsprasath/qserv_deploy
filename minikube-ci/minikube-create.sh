set -e
set -x

MINIKUBE_BIN=/tmp/minikube
KUBECTL_BIN=/tmp/kubectl

curl -Lo "$MINIKUBE_BIN" \
https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x "$MINIKUBE_BIN"

curl -Lo "$KUBECTL_BIN" \
https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x "$KUBECTL_BIN"

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir -p $HOME/.kube
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config
sudo -E "$MINIKUBE_BIN" start --vm-driver=none

# this for loop waits until kubectl can access the api server that Minikube has created
for i in {1..150}; do # timeout for 5 minutes
   "$KUBECTL_BIN" get pods &> /dev/null
   if [ $? -ne 1 ]; then
      break
  fi
  sleep 2
done
