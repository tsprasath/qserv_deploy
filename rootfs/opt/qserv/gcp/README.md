# Create a GKE cluster for Qserv

```shell
# Create env.sh symlink to desired configuration
ln -s env.qserv-cluster.sh env.sh

# Edit file to set up cluster attribute
vi env.sh

# Create GKE cluster
./create-gke-cluster.sh

# Create node pool for czar and worker
./setup-nodepools.sh
```
