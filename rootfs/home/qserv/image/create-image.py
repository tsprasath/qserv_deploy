#!/usr/bin/env python

"""
Create an image containing Docker by taking
a snapshot from an instance,

Script performs these tasks:
  - launch instance from image
  - install docker via cloud-init
  - create a qserv user
  - take a snapshot
  - shut down and delete the instance created

@author  Oualid Achbal, IN2P3

"""

from __future__ import absolute_import, division, print_function

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import argparse
import logging
import sys

# ----------------------------
# Imports for other modules --
# ----------------------------
import cloudmanager

# -----------------------
# Exported definitions --
# -----------------------


def get_cloudconfig():
    """
    Return cloud init configuration in a string
    """
    userdata = '''
#cloud-config

bootcmd:
- [ cloud-init-per, instance, yumclean, 'yum', 'clean', 'all']
- [ cloud-init-per, instance, yumclean, 'rm', '-rf', '/var/cache/yum']
- [ cloud-init-per, instance, yumepelrepo, 'yum', 'install', '-y', 'epel-release']
- [ cloud-init-per, instance, yumepelrepo, 'yum', 'install', '-y', 'yum-utils']
- [ cloud-init-per, instance, yumdockerrepo, 'yum-config-manager', '--add-repo', 'https://download.docker.com/linux/centos/docker-ce.repo']

write_files:
- path: "/etc/yum.repos.d/kubernetes.repo"
  permissions: "0544"
  owner: "root"
  content: |
    [kubernetes]
    name=Kubernetes
    baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
           https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
- path: "/tmp/detect_end_cloud_config.sh"
  permissions: "0544"
  owner: "root"
  content: |
    #!/bin/sh
    (while [ ! -f /var/lib/cloud/instance/boot-finished ] ;
    do
      sleep 2
      echo "---CLOUD-INIT-DETECT RUNNING---"
    done
    sync
    fsfreeze -f / && read x; fsfreeze -u /
    echo "---SYSTEM READY FOR SNAPSHOT---") &

groups:
- docker

packages:
# required for gnu-parallel
- bzip2
- device-mapper-persistent-data
- ['docker-ce', '17.06.2.ce-1.el7.centos']
- ebtables
- [kubeadm, 1.10.3-0]
- [kubectl, 1.10.3-0]
- [kubelet, 1.10.3-0]
- [kubernetes-cni, 0.6.0-0]
- lvm2
- parallel
- util-linux

runcmd:
- ['setenforce', '0']
- ['sed', '-i', 's/SELINUX=enforcing/SELINUX=disabled/', '/etc/sysconfig/selinux']
- ['systemctl', 'enable', 'docker.service']
- ['systemctl', 'enable', 'kubelet.service']
- ['/tmp/detect_end_cloud_config.sh']

package_upgrade: true
package_reboot_if_required: true
timezone: Europe/Paris

final_message: "The system is finally up, after $UPTIME seconds"
'''

    return userdata


if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description='Create Openstack image containing Docker.')

        cloudmanager.add_parser_args(parser)
        args = parser.parse_args()

        cloudmanager.config_logger(args.verbose, args.verboseAll)

        cloudManager = cloudmanager.CloudManager(
            config_file_name=args.configFile,
            create_snapshot=True)

        userdata_snapshot = get_cloudconfig()

        previous_snapshot = cloudManager.nova_snapshot_find()

        if args.cleanup:
            if previous_snapshot is not None:
                logging.debug("Removing previous snapshot: %s", cloudManager.snapshot_name)
                cloudManager.nova_snapshot_delete(previous_snapshot)
        elif previous_snapshot is not None:
            logging.critical("Destination snapshot: %s already exist", cloudManager.snapshot_name)
            sys.exit(1)

        instance_id = "source"
        instance_for_snapshot = cloudManager.nova_servers_create(
            instance_id, userdata_snapshot, cloudManager.snapshot_flavor)

        # Wait for the instance boot complete
        cloudManager.wait_active(instance_for_snapshot)

        # Wait for cloud config completion
        cloudManager.detect_end_cloud_config(instance_for_snapshot)

        cloudManager.nova_snapshot_create(instance_for_snapshot)

        # Delete instance after taking a snapshot
        cloudManager.delete_server(instance_for_snapshot)

    except Exception as exc:
        logging.critical('Exception occured: %s', exc, exc_info=True)
        sys.exit(1)
