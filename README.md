# kind-kustomize-flux

This tutorial assume that you already have the `kind`, `terraform` and `flux` binaries installed for your platform.

# Set-up

1. Create a `kind` cluster.

    ```bash
    kind create cluster --name poc-cluster
    ```
   
2. Install `flux` onto the cluster

   ```bash
   flux install
   ```
   
3. Terraform init

   ```bash
   terraform init
   ```

4. Check that the `default` namespace has no pods:
    
   ```bash
   kubectl get pods
   ```

5. Apply the `terraform` resources

   ```bash
   terraform apply -auto-approve
   ```
   
6. Check that the pod is now in place, created automatically by the flux kustomize controller (wait 30s):

    ```bash
    kubectl get pods
    ```
   Should return:

   ```bash
   NAME        READY   STATUS    RESTARTS   AGE
   nginx-pod   1/1     Running   0          9s
   ```   

# Testing

Now, play with the `main.tf` file, if we change the path and use a non-existent one, e.g.

```hcl
path = "./manifests/prod2"
```

And apply the changes:

```bash
terraform apply -auto-approve
```

The flux controller simply won't do anything, as it won't find the path. 

Check in the logs:

```bash
kubectl get pods -n flux-system -l app=kustomize-controller -o name | xargs -I {} kubectl logs -n flux-system {}
```

Should return:

```bash
{"level":"error","ts":"2024-11-13T17:02:59.892Z","msg":"Reconciliation failed after 467.22062ms, next try in 1m0s","controller":"kustomization","controllerGroup":"kustomize.toolkit.fluxcd.io","controllerKind":"Kustomization","Kustomization":{"name":"local-manifests","namespace":"flux-system"},"namespace":"flux-system","name":"local-manifests","reconcileID":"df8f8c19-09bb-4307-a8c1-460d6cc5a373","revision":"main@sha1:40e30ea908dea10e5dc7de9e7e61814de57bf9fd","error":"kustomization path not found: stat /tmp/kustomization-3520463713/manifests/prod2: no such file or directory"}
```

And you can see that the pod is still in place, even with `prune: true`:

```bash
kubectl get pods
```

If we change the path in `main.tf` to `cluster-0`, changing:

```hcl
path = "./manifests/prod/cluster-0"
```

And apply the changes:

```bash
terraform apply -auto-approve
```

It will stop complaining, because the path is now correct, but since it renderized manifest is the same in both `prod` and `prod/cluster-0` folders, it won't do anything.

Execute:

```bash
kubectl get pods -n flux-system -l app=kustomize-controller -o name | xargs -I {} kubectl logs -n flux-system {}
```

And you will see:

```bash
{"level":"error","ts":"2024-11-13T17:07:01.837Z","msg":"Reconciliation failed after 490.063841ms, next try in 1m0s","controller":"kustomization","controllerGroup":"kustomize.toolkit.fluxcd.io","controllerKind":"Kustomization","Kustomization":{"name":"local-manifests","namespace":"flux-system"},"namespace":"flux-system","name":"local-manifests","reconcileID":"b2274d98-db1c-4476-bcb9-5c10e37fec45","revision":"main@sha1:40e30ea908dea10e5dc7de9e7e61814de57bf9fd","error":"kustomization path not found: stat /tmp/kustomization-4199035883/manifests/prod2: no such file or directory"}
{"level":"info","ts":"2024-11-13T17:07:50.053Z","msg":"server-side apply completed","controller":"kustomization","controllerGroup":"kustomize.toolkit.fluxcd.io","controllerKind":"Kustomization","Kustomization":{"name":"local-manifests","namespace":"flux-system"},"namespace":"flux-system","name":"local-manifests","reconcileID":"ac17151c-9c7f-4a3c-b600-87916bc2082c","output":{"Pod/default/nginx-pod":"unchanged"},"revision":"main@sha1:40e30ea908dea10e5dc7de9e7e61814de57bf9fd"}
{"level":"info","ts":"2024-11-13T17:07:50.074Z","msg":"Reconciliation finished in 613.16027ms, next run in 1m0s","controller":"kustomization","controllerGroup":"kustomize.toolkit.fluxcd.io","controllerKind":"Kustomization","Kustomization":{"name":"local-manifests","namespace":"flux-system"},"namespace":"flux-system","name":"local-manifests","reconcileID":"ac17151c-9c7f-4a3c-b600-87916bc2082c","revision":"main@sha1:40e30ea908dea10e5dc7de9e7e61814de57bf9fd"}
```

Note that it did nothing after the previous error `unchanged` and that the nginx pod is still in place:

```bash
kubectl get pods
```