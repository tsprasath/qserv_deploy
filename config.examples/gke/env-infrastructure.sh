# Parameters related to GKE instructure

NODES=$(kubectl get nodes -o go-template='{{range .items}}{{.metadata.name}} {{end}}' | egrep "^gke-")
if [ $? ]
then
    GKE=true
else
    >&2 echo "ERROR: no GKE nodes found"
fi

MEM_REQUEST="30G"

# Size for GKE volumes
STORAGE_SIZE="3Ti"

# Force Qserv master to first node, in order to be consistent with local storage
# for bare-metal.
# Might evolve in the long term.
i=0
for node in $NODES
do
    if [ $i -eq 0 ]; then
        MASTER="$node"
    else
        WORKERS="$WORKERS $node"
    fi
    i=$((i+1))
done
