#!/bin/bash

#  parallel management of service service on all nodes 

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

usage() {
    cat << EOD
Usage: $(basename "$0") service action

Available options:
  -h            This message

Manage <service> on all remote nodes ($MASTER $WORKERS).
<action> must be in (start, stop, restart, status)

EOD
}

# Get the options
while getopts hu: c ; do
    case $c in
        h) usage ; exit 0 ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 2 ] ; then
    usage
    exit 2
fi

SERVICE="$1"
ACTION="$2"

echo "$ACTION $SERVICE service on all nodes"
parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo /bin/systemctl  daemon-reload && \
     sudo /bin/systemctl ${ACTION} ${SERVICE}.service && \
     echo \"$SERVICE\" ${ACTION}: ok"
