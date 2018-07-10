set -e
set -x

sudo /tmp/minikube delete || echo "WARN: unable to delete minikube"
sudo rm -rf /etc/kubernetes
sudo rm -rf /root/.kube
sudo rm -rf /root/.minikube
rm -rf $HOME/.kube
rm -rf $HOME/.minikube
