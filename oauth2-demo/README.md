# oauth2-demo

This is the deployment definition for the oauth2-demo app.

The app will retrieve a token for the given service principal (client) and the given user.

Requires the following secret to be added to the cluster:

```text
kubectl create secret generic oauth2-demo-secrets \
 --from-literal=tenant_id=*** \
 --from-literal=client_id=*** \
 --from-literal=client_secret=*** \
 --from-literal=username=*** \
 --from-literal=password=***
```