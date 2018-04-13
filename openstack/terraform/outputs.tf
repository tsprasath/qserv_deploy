output "gateway_external_ip" {
	value = "${openstack_compute_instance_v2.gateway.access_ip_v4}"
}
