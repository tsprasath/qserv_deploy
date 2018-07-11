DIR=$(cd "$(dirname "$0")"; pwd -P)

export MOUNT_DOT_MK=true
export QSERV_CFG_DIR="$HOME/.qserv_deploy"

"$DIR"/../qserv-deploy.sh /opt/qserv/bin/qserv-stop
