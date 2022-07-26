#!/usr/bin/env bash

[[ -z "${MY_APP_NAME}" ]] && export MY_APP_NAME="myapp$(date +%s)"
[[ -z "${MY_GROUP_NAME}" ]] && export MY_GROUP_NAME="${MY_APP_NAME:?}Group"
[[ -z "${MY_CLUSTER_NAME}" ]] && export MY_CLUSTER_NAME="${MY_APP_NAME:?}Cluster"
[[ -z "${MY_REGISTRY_NAME}" ]] && export MY_REGISTRY_NAME="${MY_APP_NAME:?}containerregistry"
[[ -z "${MY_NODE_COUNT}" ]] && export MY_NODE_COUNT=1
[[ -z "${MY_LOCATION}" ]] && export MY_LOCATION=uksouth
[[ -z "${MY_ARGO_NAMESPACE}" ]] && export MY_ARGO_NAMESPACE="argocd"

echo "============================================= "
echo "======== Installing using variables: ======== "
echo "============================================= "
env | grep 'MY_'
