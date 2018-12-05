#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"


# Creates a GKE cluster
#gcloud auth login
gcloud config set project "$PROJECT"
gcloud beta container --project "$PROJECT" clusters create "$CLUSTER" \
    --zone "$ZONE" --username "admin" --cluster-version "CLUSTER_VERSION" \
    --machine-type "$DEFAULT_MTYPE" --image-type "COS" \
    --disk-type "pd-standard" --disk-size "100" \
    --scopes $SCOPE \
    --num-nodes "$SIZE_DEFAULT" --enable-cloud-logging --enable-cloud-monitoring \
    --network "projects/$PROJECT/global/networks/default" \
    --subnetwork "$SUBNETWORK" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard \
    --no-enable-autoupgrade --enable-autorepair
