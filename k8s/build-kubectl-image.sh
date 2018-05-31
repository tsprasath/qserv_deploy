#!/bin/sh

# Create docker image containing kops tools and scripts

# @author  Fabrice Jammes

set -e
#set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

GIT_HASH="$(git describe --dirty --always)"
TAG=${DEPLOY_VERSION:-${GIT_HASH}}

IMAGE="qserv/kubectl:$TAG"

echo "Building image $IMAGE"

docker build --tag "$IMAGE" "$DIR/kubectl"
docker push "$IMAGE"
