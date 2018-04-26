output "gateway_external_ip" {
  value = "${openstack_networking_floatingip_v2.floating_ip.address}"
}

output "cluster_hosts" {
  value = "${local.cluster_hosts}"
}
