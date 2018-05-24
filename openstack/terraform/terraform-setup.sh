#!/bin/bash

# This file must be sourced before running any terraform command
# It setup terraform to store the state of the cluster in the config dir
if [ -z "$OS_PROJECT_NAME" ]; then
	>&2 echo "ERROR: OpenStack RC file not sourced"
	return
fi

if [ -z "$CLUSTER_CONFIG_DIR" ]; then
    >&2 echo "ERROR: CLUSTER_CONFIG_DIR must be defined"
    return
fi

# Triggers specific behavior in others install scripts
export OPENSTACK=true

export TF_DATA_DIR=$CLUSTER_CONFIG_DIR/terraform

# Store the state in lsst config dir
# A bug in terraform actually prevent this
# See https://github.com/hashicorp/terraform/issues/6194
#export TF_CLI_ARGS="--state-out=$CONFIG_DIR/terraform.tfstate"

# We can't get the username in terraform from the provider
# So this prevents repeating the username in tfvars
export TF_VAR_user_name=$OS_USERNAME

export TF_VAR_lsst_config_path=$CLUSTER_CONFIG_DIR

mkdir -p $TF_DATA_DIR
