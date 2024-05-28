#!/bin/bash

# Set your GitHub repo details
owner="johnbedeir"
repo="End-to-End-DevOps-GCP-Nodejs-Postgres"
cluster_name="cluster-1-testing-env"
zone="europe-west1-d"
project_id="johnydev"
service_account_email="terraform-sa@${project_id}.iam.gserviceaccount.com"
key_ids=$(gcloud iam service-accounts keys list --iam-account=$service_account_email --format="value(name)")
filename="gcp-credentials.json"


# Check if there are any keys to delete
if [ -z "$key_ids" ]; then
    echo "No keys found for service account: $service_account_email"
    exit 0
fi

# Loop through each key ID and delete the key
for key_id in $key_ids; do
    echo "Deleting key $key_id for service account: $service_account_email"
    gcloud iam service-accounts keys delete $key_id --iam-account=$service_account_email --quiet
done

echo "All keys deleted successfully for service account: $service_account_email"

# Get GCP credentials
gcloud iam service-accounts keys create ${filename} --iam-account ${service_account_email}

gcp_credentials=$(base64 ${filename})

# Function to create or update GitHub secret
create_secret() {
    local secret_name="$1"
    local secret_value="$2"

    # Create or update the secret in the GitHub repository using the 'gh' CLI tool
    echo "Setting secret $secret_name..."
    echo $secret_value | gh secret set $secret_name --repos=$owner/$repo
    if [ $? -eq 0 ]; then
        echo "Secret $secret_name set successfully."
    else
        echo "Failed to set secret $secret_name."
        exit 1
    fi
}

# Call the function with each AWS credential
create_secret "GCP_CREDENTIALS" "${gcp_credentials}"
create_secret "GCP_PROJECT" "${project_id}"
create_secret "CLUSTER_NAME" "${cluster_name}" 
create_secret "ZONE" "${zone}" 


# Cleanup
echo "cleaning up gcp credentials..."
rm -rf ${filename}

# Print success message
echo "GCP credentials stored as GitHub secrets in the repository $owner/$repo"