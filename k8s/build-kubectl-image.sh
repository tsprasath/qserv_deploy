#!/bin/sh

# Create docker image containing kops tools and scripts

# @author  Fabrice Jammes

set -e
#set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

if [ -z "$DEPLOY_VERSION" ]; then
	echo "ERROR: undefined variable \$DEPLOY_VERSION (use 'dev' or 'testing')"
	exit 1
fi

IMAGE="qserv/kubectl:$DEPLOY_VERSION"

echo $DIR

docker build --tag "$IMAGE" "$DIR/kubectl"
docker push "$IMAGE"
