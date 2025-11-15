resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "null_resource" "jenkins_pv_pvc_maker" {
  depends_on = [ aws_eks_cluster.iti_gp_cluster, kubernetes_namespace.jenkins ]
  triggers = {
    file_hash = filesha1("${path.module}/jenkins-manifests/jenkins-pv.yaml")
    file2_hash = filesha1("${path.module}/jenkins-manifests/jenkins-pvc.yaml")
  }
  provisioner "local-exec" {
    #create the jenkins-pv and jenkins-pvc
    command = <<EOT
    aws eks update-kubeconfig --name iti-gp-cluster --region us-east-1
    kubectl apply -f ${path.module}/jenkins-manifests/jenkins-pv.yaml
    kubectl apply -f ${path.module}/jenkins-manifests/jenkins-pvc.yaml
    EOT
  }
}



resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_ecr_role.arn
    }
  }
}

resource "kubernetes_cluster_role" "jenkins_sa_role" {
  metadata {
    name = "jenkins-sa-role"
  }
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "jenkins_sa_role_binding" {
  metadata {
    name = "jenkins-sa-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins_sa_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}



resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.jenkins.metadata[0].name
  }

  set {
    name  = "controller.serviceType"
    value = "ClusterIP"
  }

  set {
    name  = "controller.jenkinsUrl"
    value = "http://jenkins.jenkins.svc.cluster.local:8080"
  }

  set {
    name  = "persistence.existingClaim"
    value = "jenkins-pvc"
}

  set {
    name  = "controller.runAsUser"
    value = "1000"
  }

  set {
    name  = "controller.fsGroup"
    value = "1000"
  }

  values = [
    yamlencode({
      controller = {
        customInitContainers = [
          {
            name    = "fix-permissions"
            image   = "busybox:latest"
            command = ["sh", "-c"]
            args    = ["chmod -R 777 /var/jenkins_home && chown -R 1000:1000 /var/jenkins_home && echo 'Permissions fixed'"]
            volumeMounts = [
              {
                name      = "jenkins-home"
                mountPath = "/var/jenkins_home"
              }
            ]
            securityContext = {
              runAsUser = 0  
              runAsNonRoot = false
              runAsGroup = 0
              allowPrivilegeEscalation = true
            }
          }
        ]
      }
    })
  ]
  

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role_binding.jenkins_sa_role_binding,
  ]
}
