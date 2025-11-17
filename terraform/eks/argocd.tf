#use alias provider to solve the failed to construct REST client issue
provider "kubernetes" {
  alias                  = "eks"
  host                   = aws_eks_cluster.iti_gp_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.iti_gp_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.iti_gp_cluster.token
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = aws_eks_cluster.iti_gp_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.iti_gp_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.iti_gp_cluster.token
  }
}



resource "kubernetes_namespace" "argocd" {
  provider = kubernetes.eks
  metadata {
    name = "argocd"
  }
  depends_on = [ aws_eks_cluster.iti_gp_cluster ]
}

resource "helm_release" "argocd" {
  provider = helm.eks
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "7.5.2" # use latest stable version

  #Set service type of argocd-server
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    aws_eks_cluster.iti_gp_cluster,
    kubernetes_namespace.argocd
  ]
}


resource "kubectl_manifest" "db_app" {
  provider = kubectl.eks
  depends_on = [ aws_eks_cluster.iti_gp_cluster, helm_release.argocd ]
  yaml_body = yamlencode({
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "db-app"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"

      "source" = {
        "repoURL"        = "https://github.com/mohamedbstar413/iti-gp-project"
        "path"           = "k8s/db"
        "targetRevision" = "main"
      }

      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "db-ns"
      }

      "syncPolicy" = {
        "automated" = {
          "prune"      = true
          "selfHeal"   = true
        }
      }
    }
  })
}


resource "kubectl_manifest" "back_app" {
  provider = kubectl.eks
  depends_on = [ aws_eks_cluster.iti_gp_cluster, helm_release.argocd, kubectl_manifest.db_app]
  yaml_body = yamlencode({
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "back-app"
      "namespace" = "argocd"
      "annotations" = {
          # images to track: repository url
          "argocd-image-updater.argoproj.io/image-list" = "910148268074.dkr.ecr.us-east-1.amazonaws.com/iti-gp-image:latest"
          # desired update strategy
          "argocd-image-updater.argoproj.io/backend.update-strategy" = "semver"
          # how to write back: "git" to commit to repo
          "argocd-image-updater.argoproj.io/git-write-back-method" = "git"
        }
    }
    "spec" = {
      "project" = "default"

      "source" = {
        "repoURL"        = "https://github.com/mohamedbstar413/iti-gp-project"
        "path"           = "k8s/back"
        "targetRevision" = "main"
      }

      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "back-ns"
      }

      "syncPolicy" = {
        "automated" = {
          "prune"      = true
          "selfHeal"   = true
        }
      }
    }
  })
}
