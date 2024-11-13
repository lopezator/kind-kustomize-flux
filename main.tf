provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_manifest" "flux_git_repository" {
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "local-repo"
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
      url      = "https://github.com/lopezator/kind-kustomize-flux"
      ref = {
        branch = "main"
      }
    }
  }
}

resource "kubernetes_manifest" "flux_kustomization" {
  provider = kubernetes

  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "local-manifests"
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
      path     = "./manifests/prod"
      prune    = true
      sourceRef = {
        kind = "GitRepository"
        name = "local-repo"
      }
    }
  }

  field_manager {
    force_conflicts = true
  }
}