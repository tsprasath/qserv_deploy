/* This terraform configuration provision a Qserv cluster on OpenStack
 * It provision Kubernetes over the server
**/

provider "openstack" {
	# OpenStack params are infered trough env vars by default
	# You must source <your-openstack-provider>-rc.sh file beforehand

	# user_name   = ""
	# tenant_name = ""
	# password    = ""
  # auth_url    = ""
  # region      = ""
}


# Local variables needed for configuration
locals {
	safe_username = "${replace(var.user_name, ".", "")}"
	ssh_key_name  = "${local.safe_username}-qserv"
}

locals {
	worker_ips    = "${openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4}"
	pet_ips       = "${list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)}"
	cluster_ips   = "${concat(local.worker_ips, local.pet_ips)}"

	worker_names  = "${openstack_compute_instance_v2.workers.*.name}"
	pet_names     = "${list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name)}"
	cluster_names = "${concat(local.worker_names, local.cluster_names)}"

	cluster_hosts = "${formatlist("%s	%s", local.cluster_ips, local.cluster_names)}"
}

### DATA SECTION ###

# Flavor of the cluster nodes
data "openstack_compute_flavor_v2" "node_flavor" {
	name = "${var.flavor}"
}

# Image of the cluster nodes
data "openstack_images_image_v2" "node_image" {
	name = "${var.snapshot}"
}

# Network of the cluster
data "openstack_networking_network_v2" "network" {
	name = "${var.network}"
}


# Cloud-Init config file filled with cluster parameters
data "template_file" "cloud_init" {
	template = "${file("cloud_config.tpl")}"

	vars {
		systemd_memlock = "${var.limit_memlock}"
		key 						= "${file("${var.ssh_private_key}.pub")}"
		registry_host   = "${var.docker_registry_host}"
		registry_port   = "${var.docker_registry_port}"
	}
}


### RESOURCE SECTION ###

# Creates a keypair from the local provided keypair
resource "openstack_compute_keypair_v2" "keypair" {
	name       = "${local.ssh_key_name}"
	public_key = "${file("${var.ssh_private_key}.pub")}"
}

# Allocate a floating ip
resource "openstack_networking_floatingip_v2" "floating_ip" {
	pool = "${var.ip_pool}"
}

# Creates the gateway (bastion) server
resource "openstack_compute_instance_v2" "gateway" {
	name      			= "${var.instance_prefix}gateway"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}gateway")}"		

	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

# Associates the floating ip to the gateway server
resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
	floating_ip = "${openstack_networking_floatingip_v2.floating_ip.address}"
	instance_id = "${openstack_compute_instance_v2.gateway.id}"
}

# Creates the k8s master
resource "openstack_compute_instance_v2" "orchestra" {
	name     = "${var.instance_prefix}orchestra"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}orchestra")}"		

	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

# Creates the Qserv master
resource "openstack_compute_instance_v2" "master" {
	name     = "${var.instance_prefix}master-1"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}master-1")}"		
	
	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

# Creates the Qserv workers
resource "openstack_compute_instance_v2" "workers" {
	count           = "${var.nb_worker}"
	name            = "${var.instance_prefix}worker-${count.index + 1}"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}worker-${count.index + 1}")}"		
	
	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

resource "null_resource" "workers_etc" {
	
	connection {
		type 				 = "ssh"
		host 				 = "${element(openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4, count.index)}"
		user 				 = "qserv"
		private_key  = "${file(var.ssh_private_key)}"
		
		bastion_host = "${openstack_networking_floatingip_v2.floating_ip.address}"
	}
		
	count = "${var.nb_worker}"

	provisioner "remote-exec" {
		inline = ["sudo sh -c \"cat << EOF >> /etc/hosts\n${join("\n", formatlist("%s %s", concat(openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4, list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)), concat(openstack_compute_instance_v2.workers.*.name, list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name))))}\nEOF\"",
				"cat /etc/hosts"]
	}
}

resource "null_resource" "orchestra_etc" {
	
	connection {
		type 				 = "ssh"
		host 				 = "${openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4}"
		user 				 = "qserv"
		private_key  = "${file(var.ssh_private_key)}"
		
		bastion_host = "${openstack_networking_floatingip_v2.floating_ip.address}"
	}

	provisioner "remote-exec" {
		inline = ["sudo sh -c \"cat << EOF >> /etc/hosts\n${join("\n", formatlist("%s %s", concat(openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4, list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)), concat(openstack_compute_instance_v2.workers.*.name, list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name))))}\nEOF\"",
				"cat /etc/hosts"]
	}
}

resource "null_resource" "master_etc" {
	
	connection {
		type 				 = "ssh"
		host 				 = "${openstack_compute_instance_v2.master.network.0.fixed_ip_v4}"
		user 				 = "qserv"
		private_key  = "${file(var.ssh_private_key)}"
		
		bastion_host = "${openstack_networking_floatingip_v2.floating_ip.address}"
	}

	provisioner "remote-exec" {
		inline = ["sudo sh -c \"cat << EOF >> /etc/hosts\n${join("\n", formatlist("%s %s", concat(openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4, list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)), concat(openstack_compute_instance_v2.workers.*.name, list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name))))}\nEOF\"",
				"cat /etc/hosts"]
	}
}


resource "null_resource" "gateway_etc" {
	
	connection {
		type 				 = "ssh"
		host 				 = "${openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4}"
		user 				 = "qserv"
		private_key  = "${file(var.ssh_private_key)}"
		
		bastion_host = "${openstack_networking_floatingip_v2.floating_ip.address}"
	}

	provisioner "remote-exec" {
		inline = ["sudo sh -c \"cat << EOF >> /etc/hosts\n${join("\n", formatlist("%s %s", concat(openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4, list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)), concat(openstack_compute_instance_v2.workers.*.name, list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name))))}\nEOF\"",
				"cat /etc/hosts"]
	}
}
