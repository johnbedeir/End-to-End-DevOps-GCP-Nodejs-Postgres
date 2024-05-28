#!/bin/bash

# Variables
cluster_name="cluster-1-testing-env"
zone="europe-west1-d" #Make sure it is the same in the terraform variables
project_id="johnydev"
repo_name="nodejs-app" # If you wanna change the repository name make sure you change it in the k8s/app.yml (Image name) 
image_name="gcr.io/${project_id}/$repo_name:latest"
dbsecretname="db-password"
app_namespace="nodejs-app"
monitoring_namespace="monitoring"
alertmanager_svc="kube-prometheus-stack-alertmanager"
prometheus_svc="kube-prometheus-stack-prometheus"
grafana_svc="kube-prometheus-stack-grafana"
# End Variables

# update helm repos
helm repo update

# Google cloud authentication
echo "--------------------GCP Login--------------------"
gcloud auth login

# Get GCP credentials
echo "--------------------Get Credentials--------------------"
gcloud iam service-accounts keys create terraform/gcp-credentials.json --iam-account terraform-sa@${project_id}.iam.gserviceaccount.com

# Build the infrastructure
echo "--------------------Creating GKE--------------------"
echo "--------------------Creating GCR--------------------"
echo "--------------------Deploying Monitoring--------------------"
cd terraform && \ 
terraform init 
terraform apply -auto-approve
cd ..

# Update kubeconfig
echo "--------------------Update Kubeconfig--------------------"
gcloud container clusters get-credentials ${cluster_name} --zone ${zone} --project ${project_id}

# remove preious docker images
echo "--------------------Remove Previous build--------------------"
docker rmi -f $image_name || true

# build new docker image with new tag
echo "--------------------Build new Image--------------------"
docker build -t $image_name .

#GCR Authentication
echo "--------------------Authenticate Docker with GCR--------------------"
gcloud auth configure-docker

# push the latest build to dockerhub
echo "--------------------Pushing Docker Image--------------------"
docker push $image_name

# create app_namespace
echo "--------------------creating Namespace--------------------"
kubectl create ns ${app_namespace} || true

# Generate database password
echo "--------------------Generate DB password--------------------"
DB_PASSWORD=$(openssl rand -base64 12)

# Store the generated password in k8s secrets
echo "--------------------Store the generated password in k8s secret--------------------"
kubectl create secret generic $dbsecretname --from-literal=DB_PASSWORD=$DB_PASSWORD --namespace=$app_namespace || true

# Deploy the application
echo "--------------------Deploy App--------------------"
kubectl apply -n $app_namespace -f k8s

# Wait for application to be deployed
echo "--------------------Wait for all pods to be running--------------------"
sleep 90s

echo "App_URL:" $(kubectl get svc ${app_svc} -n ${app_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')
echo ""
echo "Alertmanager_URL:" $(kubectl get svc ${alertmanager_svc} -n ${monitoring_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')
echo ""
echo "Prometheus_URL:" $(kubectl get svc ${prometheus_svc} -n ${monitoring_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')
echo ""
echo "Grafana_URL: " $(kubectl get svc ${grafana_svc} -n ${monitoring_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')