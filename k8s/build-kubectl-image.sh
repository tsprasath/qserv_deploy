#!/bin/sh

# Create docker image containing kops tools and scripts

# @author  Fabrice Jammes

set -e
#set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)

if [ -z "$TAG" ]; then
	echo "ERROR: undefined variable \$TAG (use 'latest' or 'testing')"
	exit 1
fi

IMAGE="qserv/kubectl:$TAG"

echo $DIR

docker build --tag "$IMAGE" "$DIR/kubectl"
docker push "$IMAGE"
