#!/usr/bin/env python3
"""
Create k8s pods configuration files

@author Fabrice Jammes, IN2P3
"""

from __future__ import absolute_import, division, print_function

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import argparse
try:
    import configparser
except ImportError:
    import ConfigParser as configparser  # python2
import logging
import os
import sys
import warnings
import yaml

# ----------------------------
# Imports for other modules --
# ----------------------------

# -----------------------
# Exported definitions --
# -----------------------

# --------------------
# Local definitions --
# --------------------

# Support dumping of long strings as block literals or folded blocks in yaml
#


def _str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar('tag:yaml.org,2002:str', data,
                                       style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)


def _config_logger(verbose):
    """
    Configure the logger
    """
    verbosity = len(verbose)
    levels = {0: logging.WARNING, 1: logging.INFO, 2: logging.DEBUG}

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


def _get_container_id(container_name):
    for i, container in enumerate(yaml_data['spec']['containers']):
        if container['name'] == container_name:
            return i
    return None

def _get_init_container_id(container_name):
    for i, container in enumerate(yaml_data['spec']['initContainers']):
        if container['name'] == container_name:
            return i
    return None

def _is_master():
    labels = yaml_data['metadata']['labels']
    return labels.get('node') == 'master'

def _mount_volume(container_name, container_dir, volume_name):
    """
    Map host_dir to container_dir in pod configuration
    using volume technology
    @param container_name: container name in yaml file
    @param container_dir: directory in container
    @param volume_name: name of volume made containing host_dir
    """
    container_id = _get_container_id(container_name)
    if container_id is not None:
        if 'volumeMounts' not in yaml_data['spec']['containers'][container_id]:
            yaml_data['spec']['containers'][container_id]['volumeMounts'] = []

        volume_mounts = yaml_data['spec']['containers'][container_id]['volumeMounts']
        volume_mount = {'mountPath': container_dir, 'name': volume_name}
        volume_mounts.append(volume_mount)

def _mount_init_volume(init_container_name, container_dir, volume_name):
    """
    Map host_dir to container_dir in pod configuration
    using volume technology, for initContainer
    @param container_name: initContainer name in yaml file
    @param container_dir: directory in container
    @param volume_name: name of volume made containing host_dir
    """
    container_id = _get_init_container_id(init_container_name)
    if container_id is not None:
        if 'volumeMounts' not in yaml_data['spec']['initContainers'][container_id]:
            yaml_data['spec']['containers'][container_id]['volumeMounts'] = []

        volume_mounts = yaml_data['spec']['initContainers'][container_id]['volumeMounts']
        volume_mount = {'mountPath': container_dir, 'name': volume_name}
        volume_mounts.append(volume_mount)


def _add_volume(host_dir, volume_name):
    if 'volumes' not in yaml_data['spec']:
        yaml_data['spec']['volumes'] = []
    volume = {'hostPath': {'path': host_dir},
              'name': volume_name}
    volumes = yaml_data['spec']['volumes']
    volumes.append(volume)


def _add_emptydir_volume(volume_name):
    if 'volumes' not in yaml_data['spec']:
        yaml_data['spec']['volumes'] = []

    volume = {'emptyDir': {},
              'name': volume_name}
    volumes = yaml_data['spec']['volumes']
    volumes.append(volume)


if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(description='Create k8s pods configuration file from template')

        parser.add_argument('-v', '--verbose', dest='verbose', default=[],
                            action='append_const', const=None,
                            help='More verbose output, can use several times.')
        parser.add_argument('-i', '--ini', dest='iniFile',
                            required=True, metavar='PATH',
                            help='ini file used to fill yaml template')
        parser.add_argument('-r', '--resource', dest='resourcePath',
                            required=True, metavar='PATH',
                            help='path to resource directory (i.e. shell '
                            'scripts) inserted inside yaml')
        parser.add_argument('-t', '--template', dest='templateFile',
                            required=True, metavar='PATH',
                            help='yaml template file')
        parser.add_argument('-o', '--output', dest='yamlFile',
                            required=True, metavar='PATH',
                            help='pod configuration file, in yaml')

        args = parser.parse_args()

        _config_logger(args.verbose)

        config = configparser.RawConfigParser()

        with open(args.iniFile, 'r') as f:
            config.readfp(f)

        with open(args.templateFile, 'r') as f:
            yaml_data = yaml.load(f)

        resourcePath = args.resourcePath
        yaml.add_representer(str, _str_presenter)

        yaml_data['metadata']['name'] = config.get('spec', 'pod_name')
        yaml_data['spec']['hostname'] = config.get('spec', 'pod_name')

        # Configure xrootd
        #
        container_id = _get_container_id('xrootd')
        if container_id is not None:
            container = yaml_data['spec']['containers'][container_id]
            command = ["/bin/su"]
            _args = ["qserv", "-c", "sh /config-start/start.sh"]
            # Uncomment line below for debugging purpose
            # command = ["tail", "-f", "/dev/null"]
            container['command'] = command
            container['args'] = _args
            container['image'] = config.get('spec', 'image')
            yaml_data['spec']['containers'][container_id] = container

        # Configure mysql-proxy
        #
        container_id = _get_container_id('proxy')
        if container_id is not None:
            container = yaml_data['spec']['containers'][container_id]
            container['image'] = config.get('spec', 'image')

        # Configure wmgr
        #
        container_id = _get_container_id('wmgr')
        if container_id is not None:
            container = yaml_data['spec']['containers'][container_id]
            container['image'] = config.get('spec', 'image')

        # Configure mariadb
        #
        container_id = _get_container_id('mariadb')
        if container_id is not None:
            yaml_data['spec']['containers'][container_id]['image'] = config.get('spec', 'image')
            command = ["sh", "/config-start/mariadb-start.sh"]
            yaml_data['spec']['containers'][container_id]['command'] = command

        if config.get('spec', 'host') != "-MK-":
            node_selector = dict()
            node_selector['kubernetes.io/hostname'] = config.get('spec', 'host')
            yaml_data['spec']['nodeSelector'] = node_selector

        # initContainer
        #
        yaml_data['spec']['initContainers'] = []
        # initContainer: configure qserv-data-dir using mariadb image
        #
        init_container = dict()
        command = ["sh", "/config-mariadb/mariadb-configure.sh"]
        init_container['command'] = command
        init_container['image'] = config.get('spec', 'image')
        init_container['imagePullPolicy'] = 'Always'
        init_container['name'] = 'init-data-dir'
        init_container['volumeMounts'] = []
        yaml_data['spec']['initContainers'].append(init_container)

        _mount_init_volume('init-data-dir', '/config-mariadb', 'config-mariadb-configure')
        _mount_init_volume('init-data-dir', '/config-mariadb-etc', 'config-mariadb-etc')
        _mount_init_volume('init-data-dir', '/config-sql', 'config-sql')


        # Attach tmp-dir to containers
        #
        volume_name = 'tmp-volume'
        mount_path = '/qserv/run/tmp'
        if config.get('spec', 'host_tmp_dir'):
            _add_volume(config.get('spec', 'host_tmp_dir'), volume_name)
        else:
            _add_emptydir_volume(volume_name)

        _mount_volume('mariadb', mount_path, volume_name)
        _mount_volume('proxy', mount_path, volume_name)
        _mount_volume('wmgr', mount_path, volume_name)
        _mount_volume('xrootd', mount_path, volume_name)

        # Attach data-dir to containers
        #
        volume_name = 'data-volume'
        mount_path = '/qserv/data'
        if config.get('spec', 'host_data_dir'):
            _add_volume(config.get('spec', 'host_data_dir'), volume_name)
        else:
            _add_emptydir_volume(volume_name)

        _mount_init_volume('init-data-dir', mount_path, volume_name)
        _mount_volume('mariadb', mount_path, volume_name)
        _mount_volume('proxy', mount_path, volume_name)
        _mount_volume('wmgr', mount_path, volume_name)
        # xrootd mmap/mlock *.MYD files and need to access mysql.sock
        _mount_volume('xrootd', mount_path, volume_name)


        with open(args.yamlFile, 'w') as f:
            f.write(yaml.dump(yaml_data, default_flow_style=False))

    except Exception as exc:
        logging.critical('Exception occurred: %s', exc, exc_info=True)
        sys.exit(1)
