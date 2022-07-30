#!/usr/bin/env bash

source args.sh "$@"


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
