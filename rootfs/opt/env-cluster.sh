# Directory containing infrastructure specification
# (ssh credentials, machine names)

# Required for bare-metal
export KUBECONFIG="${QSERV_CFG_DIR}/kubeconfig"

# ssh credentials, optional
SSH_CFG="$QSERV_CFG_DIR/ssh_config"

# ssh option for using configuration file
if [ -r "$SSH_CFG" ]; then
    SSH_CFG_OPT="-F $SSH_CFG"
else
    SSH_CFG_OPT=
fi

# Machine names
ENV_INFRASTRUCTURE_FILE="$QSERV_CFG_DIR/env-infrastructure.sh"
if [ -r "$ENV_INFRASTRUCTURE_FILE" ]; then
    . "$ENV_INFRASTRUCTURE_FILE"
else
    echo "ERROR: $ENV_INFRASTRUCTURE_FILE is not readable"
    exit 1
fi

if [ ! $CI ]; then
    # GNU parallel ssh configuration
    PARALLEL_SSH_CFG="$QSERV_CFG_DIR/sshloginfile"
    if [ -z "$CREATE_PARALLEL_SSH_CFG" -a ! -r "$PARALLEL_SSH_CFG" ]; then
        echo "ERROR: $PARALLEL_SSH_CFG is not readable"
        exit 1
    fi
fi
