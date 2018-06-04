set -e

CLOUD=$(basename $CLUSTER_CONFIG_DIR)
TARGET_DIR="$HOME/src/k8s-school/ANF/config.$CLOUD"
mkdir -p "$TARGET_DIR" 

cd $CLUSTER_CONFIG_DIR/
cp ssh_config sshloginfile env-infrastructure.sh env.sh "$TARGET_DIR"

