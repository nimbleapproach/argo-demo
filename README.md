# argo-demo
Project to demonstrate deploying images to Kubernetes via ArgoCD. This readme should provide the instructions necessary to set up a basic Kubernetes cluster which contains Argo, then use Argo to manage the deployment of an image into the cluster via command line (for possible future scripting)

## Pre-requisites
- An Azure account, create a free trial account if necessary if you're just trying it out
- A GitHub account (other repositories are available)
- This guide assumes the use of MacOS with permissions to be able to install various apps
- The said Mac has homebrew installed. See: [brew.sh](https://brew.sh)
- You are familiar with using Terminal/Command Line

## Guide
### Install the Azure Command Line Interface (CLI)
Required for interfacing with azure, run the following command:
- `brew install azure-cli`

### Install docker
This will allow you to manipulate docker images and move them between registries. It is assumed that you cannot use docker for desktop as this requires a license; run the following commands:
- `brew install docker`
- `brew install colima` (This will be used for the docker daemon)
- `colima start` (Start the daemon)

### Login to Azure CLI
This will allow you to run commands against your Azure account/subscription:
- `az login`
- Follow the login process via the browser, will want to go this way particularly if you have MFA on the account
- If you have the one subscription you'll log into it automatically, otherwise we may have to switch with the az account command
- Register the 2 providers below:
- `az provider register --namespace Microsoft.OperationsManagement`
- `az provider register --namespace Microsoft.OperationalInsights`

### Create resource group
Our services will be grouped here (feel free to change the name of the group):
- `az group create --name paulsGroup --location uksouth`
- Should see a response with **"provisioningState": "Succeeded"** in it
- It should also appear in the Azure portal after a few seconds

### Create AKS cluster
We'll create a single node cluster here for testing, production clusters will want more:
- `az aks create -g paulsGroup -n paulsAKSCluster --enable-managed-identity --node-count 1 --enable-addons monitoring`
- -g refers to the resource group we created previously
- -n specifies the name we are giving to the cluster, feel free to change
- Note this command may take several minutes to run, again look for **"provisioningState": "Succeeded"** when the response comes back

### Create a container registry
The place to store our images within Azure, we'll use the Basic service tier here for testing, likely to be different for prod
- `az acr create -g paulsGroup -n paulregistry80 --sku Basic`
- Note the name you use for the registry must be lowercase and unique across Azure
- Optionally test ACR as per the ACR quickstart link below

### Install kubectl
This is needed to interface with the AKS cluster, you can do this with:
- `sudo az aks install-cli` (Note, requires admin access)
- `az aks get-credentials` (Will get the config required by kubectl to access your cluster)
- **Potential Problem** When install-cli is run it will run a Python script against the python version that was installed as a dependency for the Azure CLI in the brew install, this resulted in a certificate issue for me. To resolve you can try running the **installcerts.sh** script that is included in this repository, you may or may not need to change the location of Python on line 3 to the one the CLI is using. This script is a copy of one from the offical Python installer.
- Optionally can test deploying to AKS as per the quickstart guide, but as we're going to get Argo to deploy there may not be particularly worthwhile

### Attach ACR to AKS
We need the AKS to be able to access the images stored in ACR:
- `az aks update -n paulsAKSCluster -g paulsGroup --attach-acr paulsregistry80`
- `az aks check-acr -n paulsAKSCluster -g paulsGroup --acr paulsregistry80`
- The second command checks the cluster can pull from ACR. **Note you may have to wait over 30 mins** for this command to report that pull succeeded. If it passed “Validating managed identity existance” [sic] and the AcrPull permission appears to be assigned to the cluster in portal then you're probably going to be fine.

### Deploy Argo to AKS
Adds Argo as a kubernetes controller to our cluster:
- `brew install argocd` (CLI for argo)
- `kubectl create namespace argocd`
- `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- `kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'` (expose the Argo API so we can use the Argo CLI or UI)
- `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo` (Gets the initial password)
- Note exposing the API as above just gives it a public IP, we will likely want to do some ingress configuration for it as per [Argo Ingress](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/), you can find the IP in Portal (you'll need this in a bit) if you go into the **Services and ingresses** section within your AKS cluster you should find an IP address listed against argo-server.
- Login on the command line with `argocd login [IP]` (eventually likely to have some internally accessible host name) user name is *admin*
- Or login at https://[IP] for the UI

### Attach repository to Argo
Argo needs to access service definition files that will be stored within a respository, this may be more easily done with the UI itself, especially if it is a private repository that you want to connect to with ssh, to do this:
- run `ssh-keygen` (do not save the generated files away from the default location if you have ssh set up personally)
- copy the public key, usually in id_rsa.pub to you allowed keys for the repository you want to attached, presumably in GitHub, it is assumed you know how to do this, ask if you don't
- In the Argo UI, go to *Settings* (the cog item on the left), select *Repositories*, then select *CONNECT REPO USING SSH* (button top left) and follow the instructions, you will need to copy the private key from the id_rsa file we created earlier.
- Assuming this works we're now ready to Add some applications!!

### Deploy helloworld app
Lets deploy something, for this I'm using a pre-existing image that is essentially a helloworld HTTP application (you may wish to create your own image). First we'll need to get our image into ACR, eventually these should be generated by our own pipelines. Note you will need to be logged into Azure (az login) and change the repository name to whatever you created in the ACR step above):
- `docker pull strm/helloworld-http`
- `docker tag strm/helloworld-http paulsregistry80.azurecr.io/helloworld-http:v1`
- `docker push paulsregistry80.azurecr.io/helloworld-http:v1`
- Now copy the helloworld directory in this repository to the repository we attached to Argo above
- Modify deployment.yaml so that the image refers to your ACR location
- Now run `argocd app create helloworld --repo git@github.com:youruser/yourrepo.git --path helloworld --dest-server https://kubernetes.default.svc --dest-namespace default` (make sure you're logged in)
- *Please note that the application name must be lowercase*
- The git repo link is the same as the one we attached previously, it'll be the clone link you can see in github
- The path is the github directory where the yaml files are for this app.
- This create command will create in manual sync mode (I think) which means no changes will be applied until you sync it directly, we can create with *--sync-policy auto* there will be an update command too, or go update it in the UI, you can also Add the app via the UI and follow the instructions
- We can check the state of our app within the UI or with `argocd app get helloworld`
- There should also be a new workload in our AKS cluster in Portal named *helloworld*
- If you used the image as above hopefully it is showing as LoadBalancer with a public IP (for testing purposes) with *Services and Ingresses* in Portal, clicking on it should open the helloworld page. If it isn't a load balancer we can patch it as we did for the argo server
- We can then do things like change the number of replicas in the deployment yaml, we should then see the app is out of sync if we do `argocd app get helloworld` or in the UI, if we are syncing manually you can then do `argocd app sync helloworld` or use the button in the UI, you would hopefully then see this change reflected in Portal.

Note this is one of many, many ways to deploy via Argo (helm charts etc.) that aren't explored here!

### Add github webhook for Argo
Argo will check the repository it is attached to every 3 minutes. If we want it to sync in a more timely manner, then we will need to configure a webhook on the repository feeding Argo. The instructions to do so are here: https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/

## Links
- [AKS Quickstart](https://docs.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)
- [ACR Quickstart](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli)
- [Argo Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
