#!/bin/bash

# Empty given directory on host nodes

# @author Fabrice Jammes SLAC/IN2P3

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/../env-cluster.sh"

# Directory owner
USER=qserv

usage() {
    cat << EOD
Usage: $(basename "$0") [options] target-dir

Available options:
  -h            This message
  -u user       Directory owner (require sudo access for current user),
                default to qserv

Empty <target-dir> on all remote nodes ($MASTER $WORKERS).
<target-dir> must be an absolute path.

EOD
}

# Get the options
while getopts hu: c ; do
    case $c in
        h) usage ; exit 0 ;;
        u) USER="OPTARG" ;;
        \?) usage ; exit 2 ;;
    esac
done
shift "$((OPTIND-1))"

if [ $# -ne 1 ] ; then
    usage
    exit 2
fi

TARGET_DIR="$1"

case "$TARGET_DIR" in
    /*) ;;
    *) echo "ERROR: expect absolute path" ; exit 2 ;;
esac

# strip trailing slash                                                                                                                                                                                             
TARGET_DIR=$(echo $TARGET_DIR | sed 's%\(.*[^/]\)/*%\1%') 

read -p "Empty $TARGET_DIR on all nodes (y/n)?" CONT
if [ "$CONT" != "y" ]; then
    echo "Aborting directory content deletion"
    exit 0
fi

parallel --nonall --tag --slf "$PARALLEL_SSH_CFG" \
    "sudo -- rm -rf $TARGET_DIR && \
     echo $TARGER_DIR removed on \$(hostname)"

