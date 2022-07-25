# Ingress Controllers
An ingress controller is essentially a proxy that can route calls to various services within our cluster without having to expose them all individually i.e. we only have to create one external IP address, one host etc.

In this example we will add an nginx Ingress Controller and configure ingress for Argo
N.B. There are a couple of Argo specific things, but this can largely be applied to other applications

## Pre-requisites
- Azure CLI is installed
- Successfully configured kubectl to connect to Azure

## Guide

### Install Helm
nginx controller is configured and deployed via helm
- `brew install helm`

### Add the controller repo
- `helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx`
- `helm repo update`

### Install the controller
- Ensure you're logged in to Azure `az login`
- Use of a static IP is assumed with an entry in DNS Zone that points to it e.g. (for illustrative purposes) *ci.nimbleapproach.com*
- You can create a static IP with the following command example:
- `az network public-ip create -g mc_paulsgroup_paulsakscluster_uksouth -n ingressIP --sku Standard --allocation-method static`
- Note the LoadBalancer SKU and Static IP SKU must match
- Run the following helm command, replace $STATIC_IP with the relevant IP:
`helm install ingress-nginx ingress-nginx/ingress-nginx \              
  --create-namespace \
  --namespace ingress-ctl \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.extraArgs.enable-ssl-passthrough="" \
  --set controller.service.loadBalancerIP=$STATIC_IP`
- Controller will be created in the *ingress-ctl* namespace
- This will give us the host *https://ci.nimbleapproach.com* as the address of the controller, navigating there should give us an nginx 404 page
- *enable-ssl-passthrough* is required for Argo
- Controller must also must not run on Windows (apparently)

### Add ingress for Argo
Controllers, also apparently, by default, can find Ingress entries on other namespaces, so we simply add an ingress definition in the argocd namespace
- The ingress definition is found in the argo-ingress.yaml file in this directory
- Add the definition with `kubectl apply -f argo-ingress.yaml --namespace argocd`
- Alternatively you can use argo-ingress-tls.yaml which will add a certificate and allow the SSL webhooks to work properly from GitHub (i.e. Without disabling the SSL check ***There is an issue here I do not fully understand at time of writing, if I add a host restriction to the rule it does not appear to route to Argo, I generally have to create the rule with the host entry to generate the certificate and then remove it to actually route it***
- That in most cases would be it, we should be able to access argo at *https://ci.nimbleapproach.com/argo*, however, we see a 404
- This is because we have altered Argo's root path and Argo must be configured for that, to do that (*if you do not change the root this does not apply*):
1. Get the argo server deployment `kubectl get deploy argocd-server -n argocd  -o yaml > argocd-server-deploy.yaml`
2. Edit *argocd-server-deploy.yaml*, find the part that looks like:

`containers:
    - command:
        - argocd-server`
and change it to:
`containers:
        - command:
            - argocd-server
            - --rootpath=/argo`
            
3. Apply the change `kubectl apply -f argocd-server-deploy.yaml --namespace argocd`
4. After a few seconds our Argo link *should* work
