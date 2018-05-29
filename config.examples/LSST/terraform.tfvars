# Use this file to tune your cluster parameters
# For a complete reference of all variables, see variables.tf
# Commented lines are optionnal parameters at default value

# Flavor of the cluster nodes
flavor = "m1.medium"

# Snapshot to use in the cluster nodes
snapshot = "qserv-kubernetes-1.10.3_docker-17.06.2"

# OpenStack network name of the cluster
network = "LSST-net"

# Prefix for all instances names
instance_prefix = "fjammes-"

# Number of workers node
# nb_worker = 2

# Number of k8s master
# nb_orchestrator = 1

# Private key used to ssh on nodes
ssh_private_key = "~/.ssh/id_rsa_openstack"

# Security group to add to nodes
security_groups = ["default", "remote SSH" ]

# OpenStack ip pool name for floating ip
ip_pool = "ext-net"

# Docker registry ip
docker_registry_host = "172.16.1.247"

# Docker registry port
# docker_registry_port = 5000

# Amout of memory which can be locked in container (in Bytes)
# Defaut to 'infinity'
limit_memlock = "10737418240"

