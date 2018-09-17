#!/usr/bin/env sh
#
# Copyright 2017-2018 The Jaeger Authors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

# Install nsenter, require in order to install Helm on minikube

set -e

sudo apt-get update
sudo apt-get install libncurses5-dev libslang2-dev gettext zlib1g-dev libselinux1-dev debhelper lsb-release pkg-config po-debconf autoconf automake autopoint libtool

WORK_DIR="$HOME/nsenter"
BUILD_DIR="$HOME/nsenter/util-linux-2.30.2"

mkdir -p "$WORK_DIR"

if [ ! -d "$BUILD_DIR" ]; then
  wget https://www.kernel.org/pub/linux/utils/util-linux/v2.30/util-linux-2.30.2.tar.gz -qO - | tar -xz -C "$WORK_DIR"
  cd "$BUILD_DIR"
  ./autogen.sh
  ./configure
  make nsenter
fi

sudo cp "$BUILD_DIR/nsenter" /usr/local/bin

