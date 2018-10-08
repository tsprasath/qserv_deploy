#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"


# Creates a 31 nodes GKE cluster

#gcloud auth login
gcloud config set project "$PROJECT"
SIZE=1
gcloud beta container --project "$PROJECT" clusters create "$CLUSTER" \
    --zone "$ZONE" --username "admin" --cluster-version "1.9.7-gke.6" \
    --machine-type "$DEFAULT_MTYPE" --image-type "COS" \
    --disk-type "pd-standard" --disk-size "100" \
    --scopes $SCOPE \
    --num-nodes "$SIZE" --enable-cloud-logging --enable-cloud-monitoring \
    --network "projects/neural-theory-215601/global/networks/default" \
    --subnetwork "projects/neural-theory-215601/regions/us-central1/subnetworks/default" \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard \
    --no-enable-autoupgrade --enable-autorepair
