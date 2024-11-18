# path-change experiment

This experiment assumes that you already have the `kind`, `terraform` and `flux` binaries installed for your platform.

# Set-up

1. Create a `kind` cluster.

    ```bash
    kind create cluster --name experiment-depends-on
    ```
   
2. Install `flux` onto the cluster

   ```bash
   flux install
   ```
   
3. Terraform init

   ```bash
   terraform init
   ```

4. Apply the `terraform` resources

   ```bash
   terraform apply -auto-approve
   ```
   
5. Check that the `flux` reconciliation is failing:

   ```bash
   kubectl get pods -n flux-system -l app=kustomize-controller -o name | xargs -I {} kubectl logs -n flux-system {}
   ```

   Should return:
   
   ```bash
   {"level":"error","ts":"2024-11-18T18:54:57.723Z","msg":"Reconciliation failed after 29.814194ms, next try in 1m0s","controller":"kustomization","controllerGroup":"kustomize.toolkit.fluxcd.io","controllerKind":"Kustomization","Kustomization":{"name":"local-manifests","namespace":"flux-system"},"namespace":"flux-system","name":"local-manifests","reconcileID":"c8cd043a-3145-4a86-a58e-2880d7cf8cfa","revision":"main@sha1:37edddfc4eaa444794ac84206b5e950c20954e10","error":"Certificate/cert-manager/example-certificate dry-run failed: no matches for kind \"Certificate\" in version \"cert-manager.io/v1\"\n"}
   ```

   And it doesn't recover, it will be failing forever.

6. Therefore, no `cert-manager` pods will be in place:

   ```bash
   kubectl get pods -n cert-manager
   ```

# Solution

1. Paste this block of code at the end of the `main.tf` file:

   ```hcl
   provider "helm" {
      kubernetes {
         config_path = "~/.kube/config"
      }
   }
   
   resource "helm_release" "cert_manager" {
      name       = "cert-manager"
      repository = "https://charts.jetstack.io"
      chart      = "cert-manager"
      namespace  = "cert-manager"
      version    = "v1.10.1"
      create_namespace = true
   
      set {
         name  = "installCRDs"
         value = "true"
      }
   }
   ```

2. Upgrade the `terraform` resources

   ```bash
   terraform init -upgrade
   ```
   
3. Apply the changes

   ```bash
    terraform apply -auto-approve
    ```

4. Check that flux stops complaining, and now reconciles:

   ```bash
   kubectl get pods -n flux-system -l app=kustomize-controller -o name | xargs -I {} kubectl logs -n flux-system {}
   ```
   
5. Check that the pods are now in place, created automatically by the flux kustomize controller (wait 30s):

   ```bash
   kubectl get pods -n cert-manager
   ```
   
    Should return:
    
    ```bash
   NAME                                       READY   STATUS    RESTARTS   AGE
   cert-manager-5f58985b79-pnn66              1/1     Running   0          2m46s
   cert-manager-cainjector-5cdbcddbc8-zdvrn   1/1     Running   0          2m46s
   cert-manager-webhook-5788d8d7c6-xh9g9      1/1     Running   0          2m46s
   ```
   
# Note

If something fails, try deleting your kind cluster and your terraform state files and try again:

```bash
kind delete cluster --name experiment-depends-on
rm .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup -r .terraform/
```
