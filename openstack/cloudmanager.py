#!/usr/bin/env python

"""
Tools to ease OpenStack infrastructure configuration
and provisioning

@author  Oualid Achbal, IN2P3
@author  Fabrice Jammes, IN2P3
@author  Benjamin Roziere, IN2P3

"""

from __future__ import absolute_import, division, print_function

# -------------------------------
#  Imports of standard modules --
# -------------------------------
try:
    import configparser
except ImportError:
    import ConfigParser as configparser  # python2
import logging
import os
import re
import subprocess
import sys
import time
import warnings

# ----------------------------
# Imports for other modules --
# ----------------------------
import shade

# ---------------------------------
# Local non-exported definitions --
# ---------------------------------

# -----------------------
# Exported definitions --
# -----------------------


def add_parser_args(parser):
    """
    Configure the parser
    """
    parser.add_argument('-v', '--verbose', dest='verbose', default=[],
                        action='append_const', const=None,
                        help='More verbose output, can use several times.')
    parser.add_argument('--verbose-all', dest='verboseAll', default=False,
                        action='store_true', help='Apply verbosity to all'
                        ' loggers, by default only loader level is set.')
    parser.add_argument('-C', '--cleanup', dest='cleanup', default=False,
                        action='store_true', help='Clean images and instances'
                        ' potentially created during a previous run')
    # parser = lsst.qserv.admin.logger.add_logfile_opt(parser)
    group = parser.add_argument_group('Cloud configuration options',
                                      'Options related to cloud-platform'
                                      'access and management')
    group.add_argument('-f', '--config', dest='configFile',
                       required=True, metavar='PATH',
                       help='Add cloud config file which contains instance'
                       ' characteristics')

    return parser


def config_logger(verbose, verboseAll):
    """
    Configure the logger
    """
    verbosity = len(verbose)
    levels = {0: logging.WARNING, 1: logging.INFO, 2: logging.DEBUG}
    if not verboseAll:
        # suppress INFO/DEBUG regular messages from other loggers
        # Disable dependencies loggers and warnings
        for logger_name in ["shade", "keystoneauth", "requests",
                            "stevedore", "urllib3"]:
            logging.getLogger(logger_name).setLevel(logging.ERROR)
        warnings.filterwarnings("ignore")
    
    logger = logging.getLogger()

    # create console handler and set level to debug
    console = logging.StreamHandler()
    # create formatter
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(name)-15s %(message)s')
    # add formatter to ch
    console.setFormatter(formatter)

    logger.handlers = [console]
    logger.setLevel(levels.get(verbosity, logging.DEBUG))


class CloudManager(object):
    """
    Application class for common definitions for creation of snapshot
    and provision qserv
    """

    def __init__(self, config_file_name, add_ssh_key=False,
                 create_snapshot=False):
        """
        Constructor parse all arguments

        @param config_file_name: define the configuration file containing
                                 cloud parameters
        @param create_snapshot:  if True, create instance from existing
                                 snapshot
                                 see 'snapshot' parameter in configuration file
                                 else, create instance from base image
                                 see 'base_image' parameter in configuration
                                 file
        @param add_ssh_key:      add ssh key only while launching instances
                                 in provision qserv.
        """

        logging.debug("Use configuration file: %s", config_file_name)
	
	self.cloud = shade.openstack_cloud()
        
        self._creds = self.cloud.auth
        logging.debug("Openstack user: %s", self._creds['username'])
        self._safe_username = self._creds['username'].replace('.', '')
        
        default_instance_prefix = "{0}-qserv-".format(self._safe_username)

        config = configparser.RawConfigParser(
            {'limit_memlock': 'infinity',
             'registry_host': None,
             'registry_port': 5000,
             'instance-prefix': default_instance_prefix,
             'net-id': None,
             'ssh-private-key': '~/.ssh/id_rsa',
             'ssh_security_group': None,
             'nb_worker': 3,
             'nb_orchestrator': 1,
             'format': None})
                
        with open(config_file_name, 'r') as config_file:
            config.readfp(config_file)

        # Read Docker related parameters
        self._limit_memlock = config.get('docker', 'limit_memlock')
        self._registry_host = config.get('docker', 'registry_host')
        self._registry_port = config.getint('docker', 'registry_port')

        # Read Openstack servers related parameters
        if create_snapshot:
            image_name = config.get('server', 'base_image')
            self.snapshot_name = config.get('server', 'snapshot')
        else:
            image_name = config.get('server', 'snapshot')

        
        self.image = self.cloud.get_image(image_name)
        if self.image is None:
            logging.critical("Image %s do not exist. Create it first",
                             image_name)
            sys.exit(1)

        flavor_name = config.get('server', 'flavor')
        self.flavor = self.cloud.get_flavor(flavor_name)

        snapshot_flavor_name = config.get('server', 'snapshot_flavor')
        self.snapshot_flavor = self.cloud.get_flavor(snapshot_flavor_name)

        self.network_name = config.get('server', 'network')
        if config.get('server', 'net-id'):
            self.net_uuid = config.get('server', 'net-id')
        else:
            self.net_uuid = None

        self.ssh_security_group = config.get('server', 'ssh_security_group')

        # Upload ssh public key
        if add_ssh_key:
            self.key = "{}-qserv".format(self._safe_username)
            self.key_filename = config.get('server', 'ssh-private-key')
            if not self.key_filename:
                raise ValueError("Unspecified ssh private key")
            self._manage_ssh_key()
        else:
            self.key = None
            self.key_filename = None

        self._hostname_tpl = config.get('server', 'instance-prefix')
        if not self._hostname_tpl:
            raise ValueError("Unspecified server name prefix")

        self.nbWorker = config.getint('server', 'nb_worker')
        self.nbOrchestrator = config.getint('server', 'nb_orchestrator')

        # Read Openstack volumes related parameters
        volume_format = config.get('volume', 'format')

        if volume_format:
            volume_first_id = config.getint('volume', 'first_id')
            volume_last_id = config.getint('volume', 'last_id')
            volume_ids = range(volume_first_id, volume_last_id + 1)
            self.volume_names = [volume_format.format(i) for i in volume_ids]
        else:
            self.volume_names = None

    def get_hostname_tpl(self):
        """
        All instances names created by current CloudManager instance
        start with returned string
        """
        return self._hostname_tpl

    def get_safe_username(self):
        """
        Returns cleaned Openstack user login
        (special characters, like -, are removed)
        """
        return self._safe_username

    def add_security_group(self, instance, security_group_name):
        """
        Add the provided security group to the server
        """
        groups = []
        group = self.cloud.get_security_group(security_group_name)
        groups.append(group)
        
        self.cloud.add_server_security_groups(instance, groups)
    
    def nova_snapshot_create(self, instance):
        """
        Shutdown instance if needed and snapshot it to an image named self.snapshot_name
        """
        logging.info("Creating Qserv snapshot '%s'", self.snapshot_name)

        try:
          self.cloud.create_image_snapshot(self.snapshot_name, instance, wait=True)
        except shade.OpenStackCloudException:
          logging.critical("Unable to create image snapshot %s", self.snapshot_name)
          sys.exit(1)

        logging.info("SUCCESS: Qserv image '%s' is active", self.snapshot_name)

    def nova_snapshot_find(self):
        """
        Returns and Openstack image named self.snapshot_name.
        Exit with error code if image is not unique.
        """
        snapshot = self.cloud.get_image(self.snapshot_name)
                
        return snapshot

    def nova_snapshot_delete(self, snapshot):
        """
        Delete an Openstack image from Glance
        :param snapshot: image to delete
        """
        try:
          deleted = self.cloud.delete_image(snapshot.id)

          if deleted:
            logging.info("Snapshot %s deleted", snapshot.name)
          else:
            logging.info("Snapshot %s not found", snapshot.name)

        except shade.OpenStackCloudException:
          logging.critical("Unable to delete %s snapshot, manual cleanup required", snapshot.name)

    def _build_instance_name(self, instance_id):
        """
        Build Openstack instance.
        First convert instance id to unicode
        and then concatenate instance name template with it
        :param instance_id: instance id
        :return:            instance name
        """
        # Strip invalid characters from instance ID
        # TODO: this fix should not be needed, we should require valid names
        instance_id = re.sub("[^-_.a-zA-Z0-9]", "", instance_id)
        instance_name = "{0}{1}".format(self._hostname_tpl, instance_id)
        return instance_name

    def nova_servers_create(self, instance_id, userdata, flavor=None):
        """
        Boot an instance and return
        """
        instance_name = self._build_instance_name(instance_id)
        logging.info("Launch an instance %s", instance_name)

        userdata = userdata.format(node_id=instance_id)
        #logging.debug("userdata %s", userdata)

        if not flavor:
            flavor = self.flavor

        if self.net_uuid is not None:
            nics = [{'net-id':self.net_uuid}]
        else:
            nics = []
	
        # Launch an instance from an image
        try:
            instance = self.cloud.create_server(name=instance_name,
               	                            image=self.image,
	                                          flavor=flavor,
        	                                  userdata=userdata,
                                                  ip_pool=self.network_name,
               	                            key_name=self.key,
                       	                    nics=nics)
        except shade.OpenStackCloudException as exception:
            logging.critical("Error while creating the instance %s: %s", instance_name, exception)
            sys.exit(1)
        
        return instance
    
    def detach_floating_ips(self, instance):
        """
        Dettach all floating ips attached to the instance
        """
        server_floats = shade.meta.find_nova_interfaces(
            instance['addresses'], ext_tag='floating')
        for fip in server_floats:
            try:
                ip = self.cloud.get_floating_ip(id=None, filters={'floating_ip_address': fip['addr']})
            except shade.OpenStackCloudURINotFound:
                continue
            if not ip:
                continue

            self.cloud.detach_ip_from_server(instance.id, ip['id'])

    def delete_server(self, instance):
        """
        Delete the provided instance from OpenStack
        """
        self.detach_floating_ips(instance)
        self.cloud.delete_server(instance.id)

    def wait_active(self, instance):
        """
        Wait for an instance to have 'ACTIVE' status
        """
        logging.debug("Waiting for instance %s to be ACTIVE", instance.name)

        self.cloud.wait_for_server(instance, auto_ip=False)
	server = self.cloud.get_server(instance.id)

        logging.info("Instance %s is %s", instance.name, server.status)

    def nova_create_server_volume(self, instance, data_volume_name):
        """
        Attach a volume to a server, in /dev/vdb
        @param instance: openstack server instance object
        @param data_volume_name: name of data volume to attach
        """
        data_volume = self.cloud.get_volume(data_volume_name)

        if data_volume is None:
            msg = "Data volume %s not found".format(data_volume_name)
            raise ValueError(msg)
        
        logging.debug("Attaching volume %s to instance %s", data_volume_name, instance.name)
        self.cloud.attach_volume(instance, data_volume, device='/dev/vdb')

    def detect_end_cloud_config(self, instance):
        """
        Wait for cloud-init completion
        """
        check_word = "---SYSTEM READY FOR SNAPSHOT---"
        found = None
        while not found:
            time.sleep(5)
            output = self.cloud.get_server_console(instance)
            logging.debug("console output: %s", output)
            logging.debug("instance: %s", instance)
            found = re.search(check_word, output)

    def nova_servers_cleanup(self):
        """
        Shut down and delete all Qserv servers
        starting with '_hostname_tpl' string.

        Raise exception if instance name prefix is empty.
        """
        if not self._hostname_tpl:
            raise ValueError("Instance prefix is empty")
        for server in self.cloud.list_servers():
            # server_name must be ascii
            if server.name.startswith(self._hostname_tpl):
                logging.debug("Cleanup existing instance %s", server.name)
                self.delete_server(server)

    def _manage_ssh_key(self):
        """
        Upload user ssh public key on Openstack instances
        """
        logging.info('Manage ssh keys: %s', self.key)
        if self.cloud.get_keypair(self.key):
            logging.debug('Remove previous ssh keys')
            self.cloud.delete_keypair(self.key)

        with open(os.path.expanduser(self.key_filename + ".pub")) as fpubkey:
            self.cloud.create_keypair(name=self.key, public_key=fpubkey.read())

    def _get_instance_fixed_ip(self, instance, network=None):
        """
        Returns the fixed (local) ip address of the instance
        """
        server = self.cloud.get_server(instance.id)
        
        return server.private_v4
 
    def attach_floating_ip(self, instance):
        """
        Attach a floating ip address to the instance
        """
        logging.debug("Waiting for floating_ip to be attached to %s", instance.name)
        floating_ip = self.cloud.add_auto_ip(instance, wait=True)
        logging.info("Attached floating ip %s to instance %s", floating_ip, instance.name)
        
        return floating_ip

    def print_ssh_config(self, instances, floating_ip):
        """
        Print ssh client configuration to local file
        """
        # ssh config
        ssh_config_tpl = '''
Host {host}
HostName {fixed_ip}
User qserv
Port 22
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
PasswordAuthentication no
ProxyCommand ssh -i {key_filename} {ssh_opts} qserv@{floating_ip}
IdentityFile {key_filename}
IdentitiesOnly yes
LogLevel FATAL
'''
        ssh_opts = "-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p"
        ssh_config = '''
Host *
    ServerAliveInterval 300
    ServerAliveCountMax 2
'''
        for instance in instances:
            fixed_ip = self._get_instance_fixed_ip(instance)
            ssh_config += ssh_config_tpl.format(host=instance.name,
                                                fixed_ip=fixed_ip,
                                                floating_ip=floating_ip,
                                                key_filename=self.key_filename,
                                                ssh_opts=ssh_opts)
        logging.debug("Create SSH client config ")

        f = open("ssh_config", "w")
        f.write(ssh_config)
        f.close()

    def check_ssh_up(self, instances):
        """
        Check if the ssh service started on all instances
        """
        for instance in instances:
            cmd = ['ssh', '-t', '-F', './ssh_config', instance.name, 'true']
            success = False
            nb_try = 0
            while not success:
                try:
                    subprocess.check_output(cmd)
                    success = True
                except subprocess.CalledProcessError as exc:
                    logging.warn("Waiting for ssh to be available on %s: %s",
                                 instance.name, exc.output)
                    nb_try += 1
                    if nb_try > 10:
                        logging.critical("No available ssh on %s OpenStack"
                                         " clean up is required",
                                         instance.name)
                        sys.exit(1)
                    time.sleep(2)
            logging.debug("ssh available on %s", instance.name)

    def update_etc_hosts(self, instances):
        """
        Update /etc/hosts file on each instances.
        Add each instance name and ip address inside it.
        """
        hostfile_tpl = "{ip}    {host}\n"

        hostfile = ""
        for instance in instances:
            # Collect IP adresses
            fixed_ip = self._get_instance_fixed_ip(instance)
            hostfile += hostfile_tpl.format(host=instance.name, ip=fixed_ip)

        for instance in instances:
            cmd = ['ssh', '-t', '-F', './ssh_config', instance.name,
                   'sudo sh -c '
                   '"echo \'{hostfile}\' >> /etc/hosts"'.format(
                       hostfile=hostfile)]
            try:
                subprocess.check_output(cmd)
            except subprocess.CalledProcessError as exc:
                logging.error("ERROR while updating /etc/hosts: %s",
                              exc.output)
                sys.exit(1)
            logging.debug("/etc/hosts updated on %s", instance.name)

    def mount_volume(self, instances):
        """
        Mount /dev/vdb1 on /mnt/qserv on each instance
        """
        for instance in instances:
            cmd = ['ssh', '-t', '-F', './ssh_config', instance.name,
                   'sudo sh -c "/tmp/mount_volume.sh"']
            try:
                subprocess.check_output(cmd)
            except subprocess.CalledProcessError as exc:
                logging.error("ERROR failed to mount /dev/vdb1 on %s: %s",
                              instance.name,
                              exc.output)
                sys.exit(1)
            logging.debug("/dev/vdb1 mounted on %s", instance.name)

    def build_cloudconfig(self):
        """
        Build cloudconfig configuration

        """

        cloud_config = '''
#cloud-config


host: {hostname_tpl}
fqdn: {hostname_tpl}

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
    {{{{
      "storage-driver": "overlay",
      {registry_json}
    }}}}

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
    {systemd_memlock}

users:
- name: qserv
  gecos: Qserv daemon
  groups: docker
  lock-passwd: true
  shell: /bin/bash
  ssh-authorized-keys:
  - {key}
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
  '''

        fpubkey = open(os.path.expanduser(self.key_filename + ".pub"))
        public_key = fpubkey.read()

        if self._registry_host:
            registry_json_fmt = ("\"insecure-registries\": [\"{registry_host}\"],\n"
                                 "      \"registry-mirrors\":[\"http://{registry_host}:{registry_port}\"]")
            registry_json = registry_json_fmt.format(registry_host=self._registry_host,
                                                     registry_port=self._registry_port)

        # daemon.json default-ulimits parameter is overridden by LimitMEMLOCK
        # parameter, from systemd, for unknown reason
        systemd_memlock = "LimitMEMLOCK={}".format(self._limit_memlock)

        userdata = cloud_config.format(hostname_tpl=self._hostname_tpl + "{node_id}",
                                       key=public_key,
                                       registry_json=registry_json,
                                       systemd_memlock=systemd_memlock)

        logging.debug("cloud-config userdata: \n%s", userdata)
        return userdata
