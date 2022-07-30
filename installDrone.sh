#!/usr/bin/env bash

# https://devhints.io/bash is cool

# ensure we're logged in
source argoLogin.sh
source args.sh "$@"

# assumes argocd is logged in
exitWhenNotSet() {
  echo "MY_ARGO_IP '$MY_ARGO_IP', MY_ARGO_PWD '$MY_ARGO_PWD', MY_GITHUB_OAUTH_CLIENT_ID '$MY_GITHUB_OAUTH_CLIENT_ID' and MY_GITHUB_CLIENT_SECRET '$MY_GITHUB_CLIENT_SECRET' are all required";
  exit 1
}

# the github oauth client id comes from the github oauth app (User -> Settings -> Developer Settings -> OAuth Apps -> Drone
[[ -z "${MY_GITHUB_OAUTH_CLIENT_ID}" ]] && exitWhenNotSet;
[[ -z "${MY_GITHUB_CLIENT_SECRET}" ]] && exitWhenNotSet;
[[ -z "$MY_ARGO_IP" ]] && exitWhenNotSet;
[[ -z "$MY_ARGO_PWD" ]] && exitWhenNotSet;

echo "MY_ARGO_IP is $MY_ARGO_IP, MY_ARGO_PWD is $MY_ARGO_PWD"

kubectl get namespace drone || (echo "creating drone namespace" && kubectl create namespace drone)

echo "created drone namespace"

# kubectl create secret generic drone-secrets --namespace=drone --from-literal=githubclientid="$MY_GITHUB_OAUTH_CLIENT_ID" --from-literal=githubclientsecret="$MY_GITHUB_SECRET" --from-literal=rpcsecret="$MY_RPC_SECRET"

# note: Leave 'Namespaces' unset (e.g. "All namespaces") in the cluster settings, otherwise you'll get an error
# about not being able to use persistent volume claims in a managed namespace

# install drone server
argocd app create droneserver --repo "${MY_REPO_URL}" --path drone-server --dest-server https://kubernetes.default.svc --dest-namespace drone --sync-policy auto

# install drone runners
argocd app create dronerunner --repo "${MY_REPO_URL}" --path drone-runner --dest-server https://kubernetes.default.svc --dest-namespace drone --sync-policy auto
