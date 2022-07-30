[back](../README.md)
# Ingress Controllers
An ingress controller is essentially a proxy that can route calls to various services within our cluster without having to expose them all individually i.e. we only have to create one external IP address, one host etc.

In this example we will add an nginx Ingress Controller and configure ingress for Argo
N.B. There are a couple of Argo specific things, but this can largely be applied to other applications

## Pre-requisites
A successfully configured kubectl. 
See [here](../docs/installK8s.md)

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
- Controller must also not run on Windows (apparently)

### Add ingress for Argo
Controllers, also apparently, by default, can find Ingress entries on other namespaces, so we simply add an ingress definition in the argocd namespace
- The ingress definition is found in the argo-ingress.yaml file in this directory
- Add the definition with `kubectl apply -f argo-ingress.yaml --namespace argocd`
- Alternatively you can use argo-ingress-tls.yaml which will add a certificate and allow the SSL webhooks to work properly from GitHub (i.e. Without disabling the SSL check) N.B. You'll need to do the steps in the Certificate section below before trying this.
- That in most cases would be it, we should be able to access argo at *https://ci.nimbleapproach.com*

If however you had changed the rootPath i.e. so that you would access the Argo homepage on *https://ci.nimbleapproach.com/argo* for example then you would get a 404 error. Because we have altered Argo's root path, Argo must be configured accordingly, to do that:
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

***However, doing it this way does seem to have extra issues that I do not fully understand at time of writing. If I add a host restriction to the rule it does not appear to route to Argo, I generally have to create the rule with the host entry to generate the certificate and then remove it to actually route it. So this may be best avoided***

### Certificates
If you wish to try using certificates you will need to add a cert manager and a certificate issuer, which you can do by doing the following:
- `helm repo add jetstack https://charts.jetstack.io`
- `helm repo update`
- Add custom resource definitions (CRDs) check for latest version`kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.crds.yaml`
- `helm install \                                                                                               
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.8.2`
- `kubectl create -f cert-manager-staging.yaml` (File provided in this directory, change the e-mail accordingly)
- `kubectl create -f cert-manager-production.yaml` (File provided in this directory, change the e-mail accordingly)
- **Note staging creates untrusted certificates to use for testing purposes, there are rate limits in place for production**
  [back](../README.md)