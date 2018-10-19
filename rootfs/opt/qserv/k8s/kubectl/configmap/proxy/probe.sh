#!/bin/bash
#
# This script check the health of the proxy container
# on master pod.
# On worker pod, a proxy container exists in order to
# have same pod template but it is not running any process

set -e

if [ "$HOSTNAME" = "$CZAR" ]; then
    cat < /dev/null > /dev/tcp/127.0.0.1/4040
fi
