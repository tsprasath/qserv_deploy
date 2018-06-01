#!/bin/bash

export OS_AUTH_URL=https://sbgcloud.in2p3.fr:5000/v3

export OS_PROJECT_NAME=FG_formation
export OS_PROJECT_DOMAIN_NAME=Default

export OS_USER_DOMAIN_NAME=default

export OS_USERNAME=fjammes

export OS_PASSWORD=

export OS_REGION_NAME="IPHC"

if [ -z "$OS_PASSWORD" ]; then
    >&2 echo "ERROR: enter your OpenStack Password in $CLUSTER_CONFIG_DIR/os-openrc.sh"
    exit 2
fi

