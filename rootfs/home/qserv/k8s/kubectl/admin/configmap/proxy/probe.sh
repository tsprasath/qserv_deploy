#!/bin/bash
#
# This script check the health of the proxy container

set -e

if hostname | grep -q 'worker'; then
    exit 0
fi

cat < /dev/null > /dev/tcp/127.0.0.1/4040
