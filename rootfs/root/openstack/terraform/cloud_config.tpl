#cloud-config
host: #HOST
fqdn: #HOST
write_files:
- path: "/tmp/mount_volume.sh"
  permissions: "0544"
  owner: "root"
  content: |
    #!/bin/sh
    set -e
    while [ ! -b /dev/vdb1 ] ;
    do
      sleep 2
      echo "---WAITING FOR CINDER VOLUME---"
    done
    mount /dev/vdb1 /mnt/qserv
    chown -R 1000:1000 /mnt/qserv
- path: "/etc/docker/daemon.json"
  permissions: "0544"
  owner: "root"
  content: |
    {
      "storage-driver": "overlay2",
      "storage-opts": [
        "overlay2.override_kernel_check=true"
      ],
      "insecure-registries": ["${registry_host}"],
      "registry-mirrors": ["http://${registry_host}:${registry_port}"]
    }
- path: "/etc/sysctl.d/90-kubernetes.conf"
  permissions: "0544"
  owner: "root"
  content: |
    # Enable netfilter on bridges
    # Required for weave (k8s v1.9.1) to start
    net.bridge.bridge-nf-call-iptables = 1
- path: "/etc/systemd/system/docker.service.d/docker-opts.conf"
  permissions: "0544"
  owner: "root"
  content: |
    [Service]
    LimitMEMLOCK=${systemd_memlock}
users:
- name: qserv
  gecos: Qserv daemon
  groups: docker
  lock-passwd: true
  shell: /bin/bash
  ssh-authorized-keys:
  - ${key}
  sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
  - [/tmp/detect_end_cloud_config.sh]
  - [sed, -i, 's|Environment="KUBELET_CGROUP_ARGS=|#Environment="KUBELET_CGROUP_ARGS=|', /etc/systemd/system/kubelet.service.d/10-kubeadm.conf]
  # Data and log are stored on Openstack host
  - [mkdir, -p, /qserv/custom]
  - [mkdir, /qserv/data]
  - [mkdir, /qserv/log]
  - [mkdir, /qserv/tmp]
  - [mkdir, /mnt/qserv]
  - [chown, -R, '1000:1000', /qserv]
  - [/bin/systemctl, daemon-reload]
  - [/bin/systemctl, restart,  docker]
  - [/bin/systemctl, restart,  systemd-sysctl]
