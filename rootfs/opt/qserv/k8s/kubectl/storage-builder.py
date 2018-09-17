#!/usr/bin/env python3
"""
Create k8s Persistent Volumes and Persitent Volume Claims

@author Benjamin Roziere, IN2P3
"""

# -------------------------------
#  Imports of standard modules --
# -------------------------------
import argparse
import os.path
import sys
import yaml

def _path2name(path):
    return path.replace("qserv", "").strip("/").replace("/", "-")

def _build_yaml(data_path, hostname, data_id, output_dir, template_dir):

    data_name =_path2name(data_path)

    minikube = True
    if hostname:
        minikube = False

    # yaml for persistent volume
    #
    # On minikube pvc will automatically create pv
    if not minikube:
        tpl_fname = 'qserv-pv.tpl'

        yaml_tpl = os.path.join(template_dir, tpl_fname)
        with open(yaml_tpl, 'r') as f:
            yaml_storage = yaml.load(f)

        yaml_storage['metadata']['name'] = "qserv-{}-pv-{}".format(data_name, data_id)
        yaml_storage['metadata']['labels']['dataid'] = data_id

        node_name = yaml_storage['spec']['nodeAffinity']['required']['nodeSelectorTerms'][0]['matchExpressions'][0]['values']
        node_name[0] = hostname
        yaml_storage['spec']['local']['path'] = data_path

        yaml_fname = "qserv-{}-pv-{}.yaml".format(data_name, data_id)
        yaml_fname = os.path.join(output_dir, yaml_fname)
        with open( yaml_fname, "w") as f:
            f.write(yaml.dump(yaml_storage, default_flow_style=False))

    # yaml for persistent volume claim
    #
    yaml_tpl = os.path.join(template_dir, 'qserv-pvc.tpl')
    with open(yaml_tpl, 'r') as f:
        yaml_storage = yaml.load(f)

    yaml_storage['metadata']['name'] = "qserv-{}-qserv-{}".format(data_name, data_id)
    yaml_storage['spec']['selector']['matchLabels']['dataid'] = data_id

    if minikube:
        # See
        # https://github.com/kubernetes/minikube/blob/master/deploy/addons/storageclass/storageclass.yaml
        yaml_storage['spec']['storageClassName'] = 'standard'

    yaml_fname = "qserv-{}-pvc-{}.yaml".format(data_name, data_id)
    yaml_fname = os.path.join(output_dir, yaml_fname)
    with open( yaml_fname, "w") as f:
        f.write(yaml.dump(yaml_storage, default_flow_style=False))

if __name__ == "__main__":
    try:

        parser = argparse.ArgumentParser(description="Create k8s Persistent Volumes and Claims")

        parser.add_argument('-p', '--path', dest='data_path',
                            required=True, metavar='<hostPath>',
                            help='Path on the host')
        parser.add_argument('-H', '--hostname', dest='hostname',
                            required=False, metavar='<hostname>',
                            help='Hostname of the node, do not fill it for minikube')
        parser.add_argument('-d', '--dataid', dest='data_id',
                            required=True, metavar='<dataId>',
                            help='Data ID')
        parser.add_argument('-t', '--templateDir', dest='template_dir',
                            default='/opt/qserv/k8s/kubectl/yaml',
                            required=False, metavar='<templateDir>',
                            help='yaml template directory')
        parser.add_argument('-o', '--outputDir', dest='output_dir',
                            required=True, metavar='<outputDir>',
                            help='Output directory for generated yaml files')

        args = parser.parse_args()

        data_path = args.data_path
        hostname = args.hostname
        data_id = args.data_id
        output_dir = args.output_dir
        template_dir = args.template_dir

        _build_yaml(data_path, hostname, data_id, output_dir, template_dir)

    except Exception as e:
        print(e)
        sys.exit(1)

