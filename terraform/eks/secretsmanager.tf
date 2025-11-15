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

locals {
  db_secret_json = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)
}

resource "kubernetes_secret" "db_secrets" {
  metadata {
    name      = "db-secrets"
    namespace = kubernetes_namespace.db_ns.metadata[0].name
  }

  data = {
    username = local.db_secret_json["username"]
    password = local.db_secret_json["password"]
  }

  type = "Opaque"
}


resource "kubernetes_secret" "db_secrets_back_ns" {
  metadata {
    name      = "db-secrets"
    namespace = kubernetes_namespace.back_ns.metadata[0].name
  }

  data = {
    username = local.db_secret_json["username"]
    password = local.db_secret_json["password"]
  }

  type = "Opaque"
}
