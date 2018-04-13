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
