data "tls_certificate" "eks" {
  url = aws_eks_cluster.iti_gp_cluster.identity[0].oidc[0].issuer
}

data "aws_iam_role" "cluster_role" {
  name =                "AmazonEKSAutoClusterRole"
}

data "aws_iam_openid_connect_provider" "oidc" {
  depends_on = [ aws_eks_cluster.iti_gp_cluster, aws_iam_openid_connect_provider.oidc ]
  url = aws_eks_cluster.iti_gp_cluster.identity[0].oidc[0].issuer
}

data "aws_iam_policy" "eks_ec2_container_policy" {
  name = "AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "eks_cni_policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "eks_worker_node_policy" {
  name = "AmazonEKSWorkerNodePolicy"
}

data "aws_eks_cluster_auth" "iti_gp_cluster" {
  name = aws_eks_cluster.iti_gp_cluster.name
}

data "aws_caller_identity" "current" {}