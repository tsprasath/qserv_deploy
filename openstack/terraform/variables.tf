variable "flavor" {
	description = "Flavor of the cluster nodes"
}

variable "snapshot" {
	description = "Name of the image to use in nodes"
}

variable "network" {
	description = "OpenStack network name"
}

variable "net_id" {
	description = "OpenStack subnet uuid"
}

variable "instance_prefix" {
	description = "The prefix to append to your node's name"
}

variable "nb_worker" {
	default = 2
	description = "Number of worker nodes to spawn"
}

variable "security_groups" {
	type    = "list"
	default = ["default"]
}

variable "ssh_private_key" {
	default = "~/.ssh/id_rsa"
}

variable "nb_orchestrator" {
	default = 1
}

variable "base_image" {
	default = "CentOS 7 latest"
}

variable "snapshot_flavor" {
	default = "m1.medium"
}

variable "ip_pool" {
	default = "public"
}

variable "user_name" {}

variable "docker_registry_host" {}

variable "docker_registry_port" {
	default = 5000
}

variable "limit_memlock" {
	default = "infinity"		
}

variable "lsst_config_path" {
	default = "~/.lsst/qserv-cluster"
}
