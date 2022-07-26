[back](../README.md)

# Setup for Kubernetes

This argo project assumes a running kubernetes cluster.

Ideally this is done using a separate infrastructure-as-code pipeline to create your production kubernetes service, which is out-of-scope of this repository.

(See hashicorp's terraform example [here](https://learn.hashicorp.com/tutorials/terraform/aks))

### Set up Kubernetes  
* [On Azure](azure-aks.md)
* On AWS (TODO)
* On GCP (TODO)
* Locally (TODO)

You should now have a running/working `kubectl`