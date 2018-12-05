MTYPE_CZAR="n1-standard-8"
MTYPE_DEFAULT="n1-standard-4"
MTYPE_WORKER="n1-standard-4"

CLUSTER="qserv-fjammes-0"
CLUSTER_VERSION="1.10.7-gke.6"
PROJECT="neural-theory-215601"

SCOPE="https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append"

REGION="us-central1"
SUBNETWORK="projects/$PROJECT/regions/$REGION/subnetworks/default"
ZONE="us-central1-a"

SIZE_DEFAULT=1
SIZE_CZAR=1
SIZE_WORKER=3
