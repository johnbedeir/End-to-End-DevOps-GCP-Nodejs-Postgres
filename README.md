# End-to-End-DevOps-GCP-Nodejs-Postgres

<img src=imgs/cover.png>

This repository contains scripts and Kubernetes manifests for deploying a Nodejs application on a GKE cluster with an accompanying Container Registry and Persistent Disks. The deployment includes setting up a LoadBalancer, monitoring with Prometheus and Grafana, and a continuous deployment pipeline.

## Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) configured with appropriate permissions
- [Docker](https://docs.docker.com/engine/install/) installed and configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured to interact with your Kubernetes cluster
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed
- [Helm](https://helm.sh/docs/intro/install/) installed
- [GitHub_CLI](https://github.com/cli/cli) installed
- [K9s](https://k9scli.io/topics/install/) installed
- [Studio_3T](https://studio3t.com/download/) OR [MongoDB_Compass](https://www.mongodb.com/try/download/atlascli)

## Before you run the script

### Update Script Variables:

The `build.sh` script contains a set of variables that you need to customize according to your GCP environment and deployment requirements. Here's how you can update them:

1. Open the `build.sh` script in a text editor of your choice.

2. Update the variables at the top of the script with your specific configurations:

   ```bash
   cluster_name="YOUR_GKE_CLUSTER_NAME"
   zone="YOUR_GCP_ZONE"
   project_id="YOUR_GCP_PROJECT_ID"
   ```

3. Save the changes to the `build.sh` script.

### Important Notes:

- `cluster_name`: This is the name of your Google Kubernetes Engine (GKE) cluster.
- `zone`: This is the GCP zone where your resources are located.
- `project_id`: This is your Google Cloud project ID.

### Build and Push Docker Image:

1. Ensure you are authenticated with Google Cloud:

   ```bash
   gcloud auth login
   gcloud config set project $project_id
   ```

2. Build the Docker image:

   ```bash
   docker build -t gcr.io/$project_id/$repo_name:latest .
   ```

3. Push the Docker image to Google Container Registry:

   ```bash
   docker push gcr.io/$project_id/$repo_name:latest
   ```

## Deploying the Application

### Infrastructure Setup

1. Run the following

   ```bash
   chmod +x build.sh
   ```

   ```
   ./build.sh
   ```

   This will set up the necessary GCP resources including the GKE cluster and Persistent Disks, deploying monitoring and the application, retrieve the External URL for each app.

### Accessing the Application

The application will be exposed via a LoadBalancer service. You can get the external IP address using:

```bash
kubectl get svc -n $namespace
```

Access your application at `http://<EXTERNAL_IP>`.

## Interacting with the application

To access and manage the `Database` from your local machine, you can use `k9s` to port forward the service and then connect to it using [BeeKeeper](https://www.beekeeperstudio.io/).

### Accessing the Service with k9s

1. Open `k9s` in your terminal.
2. Navigate to the `services` section by typing `:svc` and pressing `Enter`.
3. Search for the service named `postgres-service`.
4. With the `postgres-service` highlighted, press `Shift+F` to set up port forwarding to your local machine.

<img src=imgs/db-srv.png>

### Connecting to the Database

Once you've port forwarded the `postgres-service`:

1. Open Beekeeper.
2. Connect to the Postgres Database using the localhost address and the port `5432`.
3. Use the `USERNAME` you added in the k8s environment variable.
4. Get the `PASSWORD` from k8s secrets using `k9s`.

   - Navigate to `secrets`

   - Find `db-password-secret`

   - Tab on `x` in your keyboard to decode the generated password

<img src=imgs/k8s-secret.png>
<img src=imgs/secret-decode.png>

### Adding Data to the Database with Beekeeper

Create a table in the database and insert data.

1. Run the following query to create table.

```
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

2. Run the following query to insert data into the table.

```
INSERT INTO posts (title, body) VALUES ('First Post', 'This is the first post.');
INSERT INTO posts (title, body) VALUES ('Second Post', 'This is the second post.');
INSERT INTO posts (title, body) VALUES ('Third Post', 'This is the third post.');
```

4. Check the application webpage to see the updates.

<img src=imgs/app.png>

After running the queries, you should be able to verify that the new entries have been added to the database and showed on the webpage.

## CI/CD Workflows

This project is equipped with GitHub Actions workflows to automate the Continuous Integration (CI) and Continuous Deployment (CD) processes.

### Continuous Integration Workflow

The CI workflow is triggered on pushes to the `main` branch. It performs the following tasks:

- Checks out the code from the repository.
- Configures GCP credentials using secrets stored in the GitHub repository.
- Authenticate docker with GCP.
- Builds the Docker image for the Go Survey app.
- Tags the image and pushes it to the GCR.

### Continuous Deployment Workflow

The CD workflow is triggered upon the successful completion of the CI workflow. It performs the following tasks:

- Checks out the code from the repository.
- Configures GCP credentials using secrets stored in the GitHub repository.
- Sets up `kubectl` with the required Kubernetes version.
- Install Google Cloud SDK and the required plugins.
- Configure `kubectl` to use the GKE
- Authenticate `kubectl` with GKE.
- Deploys the Kubernetes manifests found in the `k8s` directory to the EKS cluster.

### Setting Up GitHub Secrets for GCP

Before using the GitHub Actions workflows, you need to set up the GCP credentials as secrets in your GitHub repository. The included `github_secrets.sh` script automates the process of adding your GCP credentials to GitHub Secrets, which are then used by the workflows. To use this script:

1. Ensure you have the GitHub CLI (`gh`) installed and authenticated.
2. Run the script with the following command:

   ```bash
   ./github_secrets.sh
   ```

This script will:

- Ensure all the `keys` for the used `service account` are deleted.
- Generate new `key` for the `service account` and encrypt it using `base64`.
- Use the GitHub CLI to set these as secrets in your GitHub repository `GCP_CREDENTIALS`, `GCP_PROJECT`, `CLUSTER_NAME`, and `ZONE`.

**Note**: It's crucial to handle GCP credentials securely. The provided script is for demonstration purposes, and in a production environment, you should use a secure method to inject these credentials into your CI/CD pipeline.

## Destroying the Infrastructure

In case you need to tear down the infrastructure and services that you have deployed, a script named `destroy.sh` is provided in the repository. This script will:

- Log in to Google Container Registry.
- Delete the specified Docker image from the Container Registry.
- Delete the Kubernetes deployment and associated resources.
- Delete the Kubernetes namespace.
- Destroy the GCP resources created by Terraform.

### Before you run

1. Open the `destroy.sh` script.
2. Ensure that the variables at the top of the script match your GCP and Kubernetes settings:

   ```bash
   project_id="YOUR_GCP_PROJECT_ID"
   repo_name="YOUR_REPO_NAME"
   ```

### How to Run the Destroy Script

1. Save the script and make it executable:

   ```bash
   chmod +x destroy.sh
   ```

2. Run the script:

   ```bash
   ./destroy.sh
   ```

This script will execute several `gcloud` and `terraform` commands to remove all resources related to your deployment. It is essential to verify that the script has completed successfully to ensure that all resources have been cleaned up and no unexpected costs are incurred.
