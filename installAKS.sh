#!/usr/bin/env bash

source initVars.sh
source args.sh $@


# install az
which az || brew install azure-cli

echo "****************** Logging in to AZ ******************"
az login

az provider register --namespace Microsoft.OperationsManagement &
az provider register --namespace Microsoft.OperationalInsights &

echo "****************** Creating $MY_GROUP_NAME in $MY_LOCATION ******************"
az group create --name "$MY_GROUP_NAME" --location "$MY_LOCATION"

echo "****************** Creating cluster ******************"
az aks create -g "$MY_GROUP_NAME" -n "$MY_CLUSTER_NAME" --enable-managed-identity --node-count "$MY_NODE_COUNT" --enable-addons monitoring


echo "****************** Creating ACR $MY_REGISTRY_NAME ******************"
az acr create -g "$MY_GROUP_NAME" -n "$MY_REGISTRY_NAME" --sku Basic

function installKubectl() {
  echo "****************** installing kubectl ******************"
  sudo az aks install-cli
}
which kubectl || installKubectl

echo "****************** Getting credentials for $MY_CLUSTER_NAME ******************"
az aks get-credentials -g "$MY_GROUP_NAME" -n "$MY_CLUSTER_NAME"

echo "****************** attaching ACR to AKS ******************"
az aks update -n "$MY_CLUSTER_NAME" -g "$MY_GROUP_NAME" --attach-acr "$MY_REGISTRY_NAME"

az aks check-acr -n "$MY_CLUSTER_NAME" -g "$MY_GROUP_NAME" --acr "$MY_REGISTRY_NAME"

echo "****************** installing ArgoCD ******************"
brew install argocd
kubectl create namespace "$MY_ARGO_NAMESPACE"
kubectl apply -n "$MY_ARGO_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n "$MY_ARGO_NAMESPACE" -p '{"spec": {"type": "LoadBalancer"}}'


# race condition -- this will fail until the cluster is ready and may take a while to succeed
function getArgoPwd() {
  echo "****************** getting ArgoCD credentials ******************"
  export MY_ARGO_PWD=$(kubectl -n "$MY_ARGO_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)
}

i=1
getArgoPwd
while [ -z "$MY_ARGO_PWD" ]
do
  echo "(retry $i) waiting for argo to start..."
  sleep 3
  i=$(( $i + 1 ))
  getArgoPwd
done
echo "MY_ARGO_PWD is $MY_ARGO_PWD"

echo "****************** getting ArgoCD IP ******************"
which jq || brew install jq
export MY_ARGO_IP=$(kubectl -n "$MY_ARGO_NAMESPACE" get svc argocd-server -o json | jq '.status.loadBalancer.ingress | .[].ip' | tr -d '"')
echo "MY_ARGO_IP is $MY_ARGO_IP"

echo "****************** log in to ArgoCD $MY_ARGO_IP w/ user admin, pwd $MY_ARGO_PWD ******************"
argocd login "$MY_ARGO_IP" --password "$MY_ARGO_PWD" --username admin --insecure
open "https://$MY_ARGO_IP"
