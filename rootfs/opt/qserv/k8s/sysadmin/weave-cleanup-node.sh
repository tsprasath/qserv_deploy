#!/bin/bash

# Reset weave net on a k8s node
# For additional information see:
# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

TMP_DIR="$(mktemp -d --suffix='-weave')"
WEAVE_PATH="$TMP_DIR/weave-install"
git clone -b "2.3.0" https://gitlab.in2p3.fr/qserv/weave-install.git $WEAVE_PATH
WEAVE_BIN="$WEAVE_PATH/weave"
sudo chmod a+x "$WEAVE_BIN"
sudo "$WEAVE_BIN" reset
rm -r "$TMP_DIR"
sudo rm -f /opt/cni/bin/weave-*
