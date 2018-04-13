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

locals {
	safe_username = "${replace(var.user_name, ".", "")}"
	ssh_key_name  = "${local.safe_username}-qserv"
}

data "openstack_compute_flavor_v2" "node_flavor" {
	name = "${var.flavor}"
}

data "openstack_images_image_v2" "node_image" {
	name = "${var.snapshot}"
}

data "openstack_networking_network_v2" "network" {
	name = "${var.network}"
}

data "template_file" "cloud_init" {
	template = "${file("cloud_config.tpl")}"

	vars {
		systemd_memlock = "${var.limit_memlock}"
		key 						= "${file("${var.ssh_private_key}.pub")}"
		registry_host   = "${var.docker_registry_host}"
		registry_port   = "${var.docker_registry_port}"
	}
}

resource "openstack_compute_keypair_v2" "keypair" {
	name       = "${local.ssh_key_name}"
	public_key = "${file("${var.ssh_private_key}.pub")}"
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
	pool = "${var.ip_pool}"
}

# Gateway server
resource "openstack_compute_instance_v2" "gateway" {
	name      			= "${var.instance_prefix}gateway"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	#user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}gateway")}"		

	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
	floating_ip = "${openstack_networking_floatingip_v2.floating_ip.address}"
	instance_id = "${openstack_compute_instance_v2.gateway.id}"
}

# K8s orchestrator
resource "openstack_compute_instance_v2" "orchestra" {
	name     = "${var.instance_prefix}orchestra"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_cloudinit_config.config.rendered, "#HOST", "${var.instance_prefix}orchestra")}"		

	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

# Qserv master
resource "openstack_compute_instance_v2" "master" {
	name     = "${var.instance_prefix}master-1"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_cloudinit_config.config.rendered, "#HOST", "${var.instance_prefix}master-1")}"		
	
	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}

# Qserv workers
resource "openstack_compute_instance_v2" "workers" {
	count           = "${var.nb_worker}"
	name            = "${var.instance_prefix}worker-${count.index + 1}"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "${openstack_compute_keypair_v2.keypair.name}"
	security_groups = "${var.security_groups}"
	user_data       = "${replace(data.template_cloudinit_config.config.rendered, "#HOST", "${var.instance_prefix}worker-${count.index + 1}")}"		
	
	network {
		uuid = "${data.openstack_networking_network_v2.network.id}"
	}
}
