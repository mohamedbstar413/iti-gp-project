# IAM Policy for my load balancer
resource "aws_iam_policy" "lb_policy" {
  name        = "AmazonEKS_LB_Policy"
  description = "Policy for ingress-nginx controller"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role with OIDC trust policy
resource "aws_iam_role" "lb_role" {
  name       = "AWS_EKS_INGRESS_NGINX_Driver_Role"
  depends_on = [aws_eks_cluster.iti_gp_cluster]
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

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lb_attachment" {
  role       = aws_iam_role.lb_role.name
  policy_arn = aws_iam_policy.lb_policy.arn
}


/*
                    Kueb auto-sclaer role
*/

# IAM Policy for my kube autoscaler
resource "aws_iam_policy" "auto_scaler_policy" {
  name        = "AmazonEKS_AutoScaling_Policy"
  description = "Policy for cluster auto scaler"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role with OIDC trust policy
resource "aws_iam_role" "auto_scaler_role" {
  name       = "AWS_EKS_Cluster_Auto_Scaler_Role"
  depends_on = [aws_eks_cluster.iti_gp_cluster]
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

# Attach policy to role
resource "aws_iam_role_policy_attachment" "auto_scaler_attachment" {
  role       = aws_iam_role.auto_scaler_role.name
  policy_arn = aws_iam_policy.auto_scaler_policy.arn
}


/*
                    EBS CSI Driver role
*/

# IAM Policy for my EBS CSI Driver
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "AmazonEKS_EBS_CSI_Driver_Policy"
  description = "Policy for AWS EBS CSI Driver"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role with OIDC trust policy
resource "aws_iam_role" "ebs_csi_role" {
  name = "AWS_EKS_EBS_CSI_Driver_Role"
  depends_on = [ aws_eks_cluster.iti_gp_cluster ]
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

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ebs_csi_attachment" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}

