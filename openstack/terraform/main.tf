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

data "openstack_compute_flavor_v2" "node_flavor" {
	name = "${var.flavor}"
}

data "openstack_images_image_v2" "node_image" {
	name = "${var.snapshot}"
}

# Gateway server
resource "openstack_compute_instance_v2" "gateway" {
	name      			= "${var.instance_prefix}gateway"
	image_id  			= "${data.openstack_images_image_v2.node_image.id}"
	flavor_id 			= "${data.openstack_compute_flavor_v2.node_flavor.id}"
	key_pair  			= "lsst-fabricejammes-qserv"
	security_groups = ["default", "remote ssh"]

	network {
		name = "${var.network}"
	}
}

# K8s orchestrator


# Qserv master


# Qserv workers


