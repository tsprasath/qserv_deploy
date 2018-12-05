# Machine type for node pools
MTYPE_CZAR="n1-highmem-64"
MTYPE_DEFAULT="n1-standard-8"
MTYPE_WORKER="n1-highmem-16"

CLUSTER="qserv-cluster"
CLUSTER_VERSION="1.10.7-gke.6"
PROJECT="neural-theory-215601"

SCOPE="https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"

REGION="us-central1"
SUBNETWORK="projects/$PROJECT/regions/$REGION/subnetworks/default"
ZONE="${REGION}-a"

# Size for node pools
SIZE_DEFAULT=1
SIZE_CZAR=0
SIZE_WORKER=0
