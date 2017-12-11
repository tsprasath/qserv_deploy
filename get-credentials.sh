# Get credentials
mkdir -p "$HOME"/.lsst/qserv-cluster
docker cp kube-master:/etc/kubernetes/admin.conf "$HOME"/.lsst/qserv-cluster/kubeconfig.dind
ln -sf "$HOME"/.lsst/qserv-cluster/kubeconfig.dind "$HOME"/.lsst/qserv-cluster/kubeconfig
ln -sf $PWD/env-infrastructure.dind.sh $HOME/.lsst/qserv-cluster/env-infrastructure.sh 

# Set correct acl on all nodes
docker exec  -- kube-node-1 sh -c "mkdir -p /qserv/log /qserv/tmp && chown -R 1000:1000 /qserv"

# Then run runkubectl.sh and qserv startup scripts...
