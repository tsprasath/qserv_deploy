set -e

CLOUD=$(basename $CLUSTER_CONFIG_DIR)
TARGET_DIR="$HOME/src/k8s-school/ANF/config.$CLOUD"
mkdir -p "$TARGET_DIR" 

cd $CLUSTER_CONFIG_DIR/
cp ssh_config env-infrastructure.sh "$TARGET_DIR"

