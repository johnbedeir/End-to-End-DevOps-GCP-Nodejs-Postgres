#!/bin/bash

# Variables
project_id="johnydev"
repo_name="nodejs-app"
# End Variables

# Get GCP credentials
gcloud iam service-accounts keys create terraform/gcp-credentials.json --iam-account terraform-sa@${project_id}.iam.gserviceaccount.com

#GCR Authentication
echo "--------------------Authenticate Docker with GCR--------------------"
gcloud auth configure-docker

echo "--------------------Enable google apis--------------------"
gcloud services enable cloudresourcemanager.googleapis.com --project ${project_id}

# delete Docker-img from GCR
echo "--------------------Deleting GCR-IMG--------------------"
gcloud container images delete gcr.io/${project_id}/${repo_name}:latest --quiet

# delete GCP resources
echo "--------------------Deleting GCP Resources--------------------"
cd terraform && \
terraform destroy -auto-approve
