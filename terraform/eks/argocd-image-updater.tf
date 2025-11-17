data "aws_iam_policy_document" "image_updater_ecr" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:DescribeImages",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "image_updater_ecr" {
  name   = "argocd-image-updater-ecr-read"
  policy = data.aws_iam_policy_document.image_updater_ecr.json
}


resource "aws_iam_role" "image_updater_role" {
  name = "argocd-image-updater-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_image_updater_policy" {
  role       = aws_iam_role.image_updater_role.name
  policy_arn = aws_iam_policy.image_updater_ecr.arn
}


resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  namespace  = "argocd"

  values = [
    yamlencode({
        serviceAccount = {
            create = true
            name = "argocd-image-updater"
            annotations = {
                "eks.amazonaws.com/role-arn" = aws_iam_role.image_updater_role.arn
            }
        }
    })
  ]
  depends_on = [ kubernetes_namespace.argocd ]
}


resource "kubernetes_secret" "argocd_image_updater_git" {
  metadata {
    name = "argocd-image-updater-git-secret"
    namespace = "argocd"
    labels = {
        #this label tells argocd image updater to use this secret to access git and update manifest files
        "argocd-image-updater.argoproj.io/secret-type" = "git"
    }
  }
  type = "Opaque"

  data = {
    url = base64encode("https://github.com/mohamedbstar413/iti-gp-project.git")
    username = base64encode("mabdelsattar413")
    password = base64encode(var.git_token)
  }
}