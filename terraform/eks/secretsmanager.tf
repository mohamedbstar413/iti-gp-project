resource "aws_secretsmanager_secret" "db_secret" {
  name =            "iti_gp_db_secret"
  recovery_window_in_days = 0 #force to delete instantly
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
  })
}

resource "aws_iam_role" "db_secret_role" {
  name = "db_secret_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn 
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]

  })
}

resource "aws_iam_policy" "db_secret_policy" {
  name = "db_secret_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadDBSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "db_secret_role_policy_attachment" {
  policy_arn = aws_iam_policy.db_secret_policy.arn
  role = aws_iam_role.db_secret_role.name
}


/*
                        install secerts inside the kubernetes cluster
*/

resource "helm_release" "secrets_store_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.5"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

}

resource "helm_release" "csi_aws_provider" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "0.3.0"

  depends_on = [
    helm_release.secrets_store_csi_driver
  ]
}


resource "kubernetes_service_account" "csi_aws_provider_sa" {
  metadata {
    name      = "secrets-store-csi-driver-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.db_secret_role.arn
    }
  }
}

resource "kubectl_manifest" "mysql_secret_provider" {
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "mysql-secret-provider"
      namespace = kubernetes_namespace.db_ns.metadata[0].name
    }
    spec = {
      provider = "aws"

      parameters = {
        objects = yamlencode([
          {
            objectName = aws_secretsmanager_secret.db_secret.name
            objectType = "secretsmanager"
          }
        ])
      }

      # Sync to Kubernetes Secret
      secretObjects = [
        {
          secretName = "mysql-credentials"
          type       = "Opaque"
          data = [
            {
              objectName = aws_secretsmanager_secret.db_secret.name
              key        = "username"
            },
            {
              objectName = aws_secretsmanager_secret.db_secret.name
              key        = "password"
            }
          ]
        }
      ]
    }
  })
}

resource "kubectl_manifest" "mysql_secret_provider_back_ns" {

  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "mysql-secret-provider"
      namespace = kubernetes_namespace.back_ns.metadata[0].name
    }
    spec = {
      provider = "aws"

      parameters = {
        objects = yamlencode([
          {
            objectName = aws_secretsmanager_secret.db_secret.name
            objectType = "secretsmanager"
          }
        ])
      }

      # Sync to Kubernetes Secret
      secretObjects = [
        {
          secretName = "mysql-credentials"
          type       = "Opaque"
          data = [
            {
              objectName = aws_secretsmanager_secret.db_secret.name
              key        = "username"
            },
            {
              objectName = aws_secretsmanager_secret.db_secret.name
              key        = "password"
            }
          ]
        }
      ]
    }
  })
}
