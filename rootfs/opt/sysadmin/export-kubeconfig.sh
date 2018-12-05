#!/bin/sh

# Export kubectl configuration

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

usage() {
    cat << EOD
Usage: $(basename "$0") [options]
Available options:
  -h            This message

  Export kubectl configuration from k8s master

EOD
}
set -x

# Get the options
while getopts h c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 0 ] ; then
	usage
    exit 2
fi

case "$KUBECONFIG" in
    /*) ;;
    *) echo "expect absolute path" ; exit 2 ;;
esac

echo "WARN: require sudo access to $ORCHESTRATOR"
ssh $SSH_CFG_OPT "$ORCHESTRATOR" 'sudo cat /etc/kubernetes/admin.conf' \
	> "$KUBECONFIG"

# Hack for Openstack (use ssh tunnel)
if [ "$OPENSTACK" = true ]; then
    "ssh-tunnel"
    sed -i -- 's,server: https://.*\(:[0-9]*\),server: https://localhost\1,g' \
        "$KUBECONFIG"
fi
echo "SUCCESS: $KUBECONFIG created"
