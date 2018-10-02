#!/bin/sh

# Help in managing a GKE cluster

CLUSTER="lsst-k8s-test"
PROJECT="neural-theory-215601"
REGION="us-central1-a"
SIZE=3

gcloud auth login
gcloud config set project "$PROJECT"
gcloud container clusters resize "$CLUSTER" --region "$REGION" --size="$SIZE"
gcloud container clusters get-credentials "$CLUSTER" --zone "$REGION" --project "$PROJECT"
