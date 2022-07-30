#!/usr/bin/env bash

source args.sh "$@"

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
