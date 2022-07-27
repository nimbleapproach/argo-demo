# Single Sign On
Argo can be configured to use Single Sign On and be integrated with various providers. This means you don't have to create any new users in Argo itself and users' access is defined via their membership of various groups defined by the provider.

## GitHub
Here we will use GitHub as our SSO provider, permissions will be governed by what team(s) your GitHub user belongs to within an Organization. This is best set up on the organization account, but you can try it on a user account as long as you can get someone to allow it access to your Organization.

### 1) Create GitHub OAuth Application
- In GitHub go to your account settings (from menu top right)
- Select *Developer Settings* from the bottom of the menu on the left.
- Select *OAuth Apps* on the right and hit the *New OAuth App* button
- Fill out the form as follows, replace the host name as necessary:

  ![add repo](./img/createOAuth.png)
- You will see something like this:

  ![add repo](./img/createdOAuthApp.png)
- Take note of the client id
- Click the *Generate a new client secret* button, and note done the value you get back (you won't be able to get it later)

### 2) Update Argo ConfigMaps
In order to enable SSO in Argo we need to update some config, namespace *argocd* is assumed, and kubectl is configured to connect to the relevant AKS cluster
Also you can use *kubectl edit* here but it didn't seem to play nice with my default editor, so this guide will pull the config down and apply it back
- `kubectl get ConfigMap argocd-cm -n argocd -o yaml > argocd-cm.yaml` to download to a file named *argocd-cm.yaml*
- Edit this file in an editor of your choice to include the following:
```yaml
data:
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: {your_github_client_id}
          clientSecret: {your_github_client_secret}
          orgs:
          - name: nimbleapproach
  url: https://argo.nimbleapproach.com/
```
- By defining *orgs* this will restrict access to users who are part of this organization, as long as the OAuth app defined in the step above has access to the same org
- It may also be possible to put the secret in argocd-secrets and reference that (one to update later)
- `kubectl apply -f argocd-cm.yaml -n argocd` to apply the changes.
- We will then also want to create a policy on who can access what.
- `kubectl get ConfigMap argocd-rbac-cm -n argocd -o yaml > argocd-rbac-cm.yaml`
- Edit to include the following:
```yaml
data:
  policy.csv: |
    p, role:org-admin, applications, *, */*, allow
    p, role:org-admin, clusters, get, *, allow
    p, role:org-admin, repositories, get, *, allow
    p, role:org-admin, repositories, create, *, allow
    p, role:org-admin, repositories, update, *, allow
    p, role:org-admin, repositories, delete, *, allow
    g, "nimbleapproach:stacks", role:org-admin
  policy.default: role:readonly
```
- Here we assign admin rights to members of the *stacks* GitHub team in the organization *nimbleapproach*, note we could've used the built-in role, role:admin, but this shows what a policy may look like
- Everybody else gets readonly access
- For more information on setting up policies see: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
- `kubectl apply -f argocd-rbac-cm.yaml -n argocd` to apply the changes.
- Theoretically, everything should update itself, however I did get some strange behaviour, including it still using SSO providers I had removed, so it may be advisable to restart a couple of services
- `kubectl scale deployment argocd-server --replicas=0 -n argocd`
- `kubectl scale deployment argocd-dex-server --replicas=0 -n argocd`
- `kubectl get deployments -n argocd` to check they are down
- Then run the same scale commands with replicas=1 to bring them back up

### Log in to Argo
When you go to the Argo homepage, you should now have a *Login via GitHub* button, clicking on this will take you to the GitHub login.
- On the first login it will likely ask you authorise the OAuth App we created previously, it will also give you the option to request access to any Organizations you have access to
- Make sure you request the Organizations you need and authorise it.
- You will then be redirected back to Argo, it will likely fail if you have just requested Organization access, and you don't yet have it
- You can check the dex logs for auth issues:
- `kubectl get pods -n argocd` to get the pods, find one for *argocd-dex-server*
- `kubectl logs argocd-dex-server-54d68db9f4-5dv9q -n argocd` example commands for logs, replace the pod name
- A successful login looks like this:
```text
time="2022-07-27T08:26:34Z" level=info msg="login successful: connector \"github\", username=\"paulpbrandon\", preferred_username=\"paulpbrandon\", email=\"paul.brandon@nimbleapproach.com\", groups=[\"nimbleapproach:stacks\"]"
```
- If it says successful here, and it doesn't let you in you can try looking at the network traffic in the browser, I've seen an issuer mismatch here, which lead me to restarting services.
- If it does log in you should see something like this in User Info:
  ![add repo](./img/argoUser.png)
- To test out access you can try adding a label to an app, if you are in the admin group (stacks team in this case) then it will save, if not it will report you don't have permission.