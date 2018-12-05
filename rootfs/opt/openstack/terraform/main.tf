/* This terraform configuration provision a Qserv cluster on OpenStack
**/

provider "openstack" {
  # OpenStack params are infered trough env vars by default, you must source <your-openstack-provider>-rc.sh file beforehand
}

### LOCAL VARS SECTION ###

# Local variables needed for configuration
locals {
  safe_username = "${replace(var.user_name, ".", "")}"
  ssh_key_name  = "${var.instance_prefix}${local.safe_username}-terraform"
}

# Cluster lists
locals {
  worker_ips  = "${openstack_compute_instance_v2.workers.*.network.0.fixed_ip_v4}"
  pet_ips     = "${list(openstack_compute_instance_v2.master.network.0.fixed_ip_v4, openstack_compute_instance_v2.orchestra.network.0.fixed_ip_v4, openstack_compute_instance_v2.gateway.network.0.fixed_ip_v4)}"
  cluster_ips = "${concat(local.worker_ips, local.pet_ips)}"

  worker_names  = "${openstack_compute_instance_v2.workers.*.name}"
  pet_names     = "${list(openstack_compute_instance_v2.master.name, openstack_compute_instance_v2.orchestra.name, openstack_compute_instance_v2.gateway.name)}"
  cluster_names = "${concat(local.worker_names, local.pet_names)}"

  cluster_hosts      = "${formatlist("%s	%s", local.cluster_ips, local.cluster_names)}"
  cluster_hosts_file = "${join("\n", local.cluster_hosts)}"
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
    key             = "${file("${var.ssh_private_key}.pub")}"
    registry_host   = "${var.docker_registry_host}"
    registry_port   = "${var.docker_registry_port}"
  }
}

# env-infrastructure file template
data "template_file" "env_infra" {
  template = "${file("env-infrastructure.tpl")}"

  vars {
    hostname_tpl   = "${var.instance_prefix}"
    worker_last_id = "${var.nb_worker}"
  }
}

# Template of a single entry in ssh_config file
data "template_file" "ssh_host_config" {
  template = "${file("ssh_host_config.tpl")}"

  vars {
    key_filename = "${var.ssh_private_key}"
    floating_ip  = "${openstack_networking_floatingip_v2.floating_ip.address}"
  }
}

# ssh_config file template
data "template_file" "ssh_config" {
  template = "${file("ssh_config.tpl")}"

  vars {
    cluster_hosts_config = "${join("\n\n", formatlist(data.template_file.ssh_host_config.rendered, local.cluster_names, local.cluster_ips))}"
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
  name            = "${var.instance_prefix}gateway"
  image_id        = "${data.openstack_images_image_v2.node_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.node_flavor.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
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
  name            = "${var.instance_prefix}orchestra-1"
  image_id        = "${data.openstack_images_image_v2.node_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.node_flavor.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = "${var.security_groups}"
  user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}orchestra-1")}"

  network {
    uuid = "${data.openstack_networking_network_v2.network.id}"
  }
}

# Creates the Qserv master
resource "openstack_compute_instance_v2" "master" {
  name            = "${var.instance_prefix}master-1"
  image_id        = "${data.openstack_images_image_v2.node_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.node_flavor.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
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
  image_id        = "${data.openstack_images_image_v2.node_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.node_flavor.id}"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = "${var.security_groups}"
  user_data       = "${replace(data.template_file.cloud_init.rendered, "#HOST", "${var.instance_prefix}worker-${count.index + 1}")}"

  network {
    uuid = "${data.openstack_networking_network_v2.network.id}"
  }
}

# Update /etc/hosts on all cluster nodes
resource "null_resource" "cluster_etc_hosts" {
  connection {
    type        = "ssh"
    host        = "${element(local.cluster_ips, count.index)}"
    user        = "qserv"
    private_key = "${file(var.ssh_private_key)}"

    bastion_host = "${openstack_networking_floatingip_v2.floating_ip.address}"
  }

  count = "${var.nb_worker + 3}"

  provisioner "remote-exec" {
    inline = [
      "sudo sh -c \"cat << EOF > /etc/hosts\n127.0.0.1  localhost\n::1  localhost\n${local.cluster_hosts_file}\nEOF\"",
    ]
  }

  triggers {
    cluster_instance_ips = "${join(",", local.cluster_ips)}"
  }
}

# Prints the env-infrastructure.sh file on local desktop
resource "null_resource" "env_infra_file" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.env_infra.rendered}' > ${var.lsst_config_path}/env-infrastructure.sh"
  }

  triggers {
    cluster_instance_ips = "${join(",", local.cluster_ips)}"
  }
}

# Prints the ssh_config for the cluster on local desktop
resource "null_resource" "ssh_config" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.ssh_config.rendered}' > ${var.lsst_config_path}/ssh_config"
  }

  triggers {
    cluster_instance_ips = "${join(",", local.cluster_ips)}"
  }
}
