[back](../README.md)

##### Note - using our own repo
If we wanted to use our own container registry - for example, by getting this from the [set up ACR in Azure step](./azure-aks.md),
we might want to "fake" a continuous integration pipeline by just tagging/pushing a docker image.

e.g., assuming we have our container registry
```
az aks check-acr -n $CLUSTER_NAME -g $GROUP_NAME --acr $REGISTRY_NAME | grep 'Your cluster can pull images from'
```

which would tell us:

```
Merged "exampleCluster" as current context in /var/folders/wl/d9x25r012l7bfw4qhbc24tw80000gp/T/tmpygtutgwp
WARNING: version difference between client (1.24) and server (1.22) exceeds the supported minor version skew of +/-1
[2022-07-26T20:52:26Z] Checking host name resolution (examplecontainerregistry1234.azurecr.io): SUCCEEDED
....
[2022-07-26T20:52:26Z] 
Your cluster can pull images from examplecontainerregistry1234.azurecr.io!
```

We could now just tag a public image (e.g. a helloworld HTTP application) and upload to our registry:
```
docker pull strm/helloworld-http
docker tag strm/helloworld-http examplecontainerregistry1234.azurecr.io/helloworld-http:v1
docker push examplecontainerregistry1234.azurecr.io/helloworld-http:v1
```
---
**Note:**
you will need to be logged into Azure (az login) and change the repository name to whatever you created in the ACR step above)
---

You can update the [helloworld/deployment.yaml](./helloworld/deployment.yaml) directory in this repository so that the image refers to your ACR location

[back](../README.md)