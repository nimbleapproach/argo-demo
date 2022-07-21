# Notes of Kustomize
## What is it?
Kustomize allows us to template a Kubernetes deployment and then apply various patches that alter that base deployment, in order to cater for various different deployments to different environments.

## How does it work
The template is contained within a *base* folder, in this repo we have a deployment and a service definition. We then have a *kustomization.yaml* file that just specifies that those resources are to be included in a deployment. Note, the base definition is deployable, we'll come back to that later.

Then for deployments to other environments kustomize has the concept of overlays, i.e. we overlay patches and any extra resources over the base definition in order to come up with a new one. The convention for overlays appears to be to create them in the folder *overlays/namespace* so in this repo we have *overlays/hw-prod* which will contain our modifications for prod.

Here you will find another *kustomization.yaml* file, in this file, we link the resources from base, you can also link any additional resources you want to create (not shown here), patches for resources defined by the base definition, and overrides for container images. There are also 2 ways to define patches, inline and by file, both are included in this example.
In this example we have 2 patches:
1. Inline patch: Targets the deployment definition and replaces the dns label annotation with a new one for prod
2. File patch: Targets the service definition and replaces an environment variable value with a different value

This example also contains an image override for the `paulsregistry80.azurecr.io/node-test` image, it will use the image tag as defined in *newTag*

## Kustomize + Argo
On adding a new deployment within the Argo UI, when you select the directory to deploy from, if a kustomize file is present Argo will auto detect that it is a kustomize deployment. The UI will show you any extra kustomize section where you can extra options such as suffixes and/or prefixes for the deployment, you can even alter the image to deploy from here too.
- Selecting the base directory will deploy just what the base template defines.
- Selecting a directory within overlays will deploy the template with the specified patches, you should see this reflected in the manifest the Argo displays for this deployment.

So if everything was deployed successful we should find:
- A version on *nimblepaultesthelloworldprod.uksouth.cloudapp.azure.com* with a message from *Outer Space*
- A version on *nimblepaultesthelloworld.uksouth.cloudapp.azure.com* with a message from *The moon*

*TODO Example of defining a kustomize app via the argo CLI* 
