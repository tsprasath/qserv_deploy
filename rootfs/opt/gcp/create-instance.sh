#!/bin/sh

set -e
set -x

DIR=$(cd "$(dirname "$0")"; pwd -P)
. "$DIR/env.sh"

INSTANCE="fjammes"

gcloud beta compute --project="$PROJECT" instances create "$INSTANCE" \
    --zone="$ZONE" --machine-type="$DEFAULT_MTYPE" --subnet=default \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --image=debian-9-stretch-v20180911 \
    --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard \
    --boot-disk-device-name=instance-1

# Attach disk
# $DISK="pd-xxx"
# gcloud compute instances attach-disk "$INSTANCE" --disk "$DISK" --zone "$ZONE"
