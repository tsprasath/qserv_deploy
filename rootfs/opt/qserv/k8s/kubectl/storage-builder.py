#!/usr/bin/env python3
"""
Create k8s Persistent Volumes and Persitent Volume Claims

@author Benjamin Roziere, IN2P3
"""

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import sys
import yaml
import argparse

def _path2name(path):
    return path.replace("qserv", "").strip("/").replace("/", "-")

def _create_persistent_volume(data_path, hostname, data_id, output_dir):

    with open("yaml/storage/qserv-storage.tpl", 'r') as f:
        yaml_storage = yaml.load(f)

    yaml_storage['metadata']['name'] = "qserv-{}-pv-{}".format(_path2name(data_path), data_id)
    yaml_storage['metadata']['labels']['dataid'] = data_id

    yaml_storage['spec']['local']['path'] = data_path
    yaml_storage['spec']['nodeAffinity']['required']['nodeSelectorTerms'][0]['matchExpressions'][0]['values'][0] = hostname

    with open("{}/qserv-{}-pv-{}.yaml".format(output_dir.rstrip("/"), _path2name(data_path), data_id), "w") as f:
        f.write(yaml.dump(yaml_storage, default_flow_style=False))


def _create_persistent_volume_claim(data_path, hostname, data_id, output_dir):

    with open("yaml/storage/qserv-pvc.tpl", 'r') as f:
        yaml_storage = yaml.load(f)

    yaml_storage['metadata']['name'] = "qserv-{}-pvc-{}".format(_path2name(data_path), data_id)

    yaml_storage['spec']['selector']['matchLabels']['dataid'] = data_id

    with open("{}/qserv-{}-pvc-{}.yaml".format(output_dir.rstrip("/"), _path2name(data_path), data_id), 'w') as f:
        f.write(yaml.dump(yaml_storage, default_flow_style=False))

if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(description="Create k8s Persistent Volumes and Claims")

        parser.add_argument('-p', '--path', dest='data_path',
                            required=True, metavar='<hostPath>',
                            help='Path on the host')
        parser.add_argument('-H', '--hostname', dest='hostname',
                            required=True, metavar='<hostname>',
                            help='Hostname of the node')
        parser.add_argument('-d', '--dataid', dest='data_id',
                            required=True, metavar='<dataId>',
                            help='Data ID')

        parser.add_argument('-o', '--outputDir', dest='output_dir',
                            required=True, metavar='<outputDir>',
                            help='Output dir for generated yaml files')

        args = parser.parse_args()

        data_path = args.data_path
        hostname = args.hostname
        data_id = args.data_id
        output_dir = args.output_dir

        _create_persistent_volume(data_path, hostname, data_id, output_dir)
        _create_persistent_volume_claim(data_path, hostname, data_id, output_dir)

    except Exception as e:
        print(e)
        sys.exit(1)

