resource "aws_eks_cluster" "iti_gp_cluster" {
  name =                    var.cluster_name
  role_arn =                data.aws_iam_role.cluster_role.arn
  vpc_config {
    subnet_ids = [ 
        var.pri_subnet_1_id,
        var.pri_subnet_2_id,
        var.pri_subnet_3_id
     ]
  }
}


resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.iti_gp_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [ data.tls_certificate.eks.certificates[0].sha1_fingerprint ]
}

/*
                NodeGroup
*/
resource "aws_eks_node_group" "iti_gp_node_group" {
  node_group_name =             "iti-gp-node-group"
  cluster_name =                aws_eks_cluster.iti_gp_cluster.name
  node_role_arn =               aws_iam_role.gp_node_iam_role.arn
  subnet_ids =                  [var.pri_subnet_1_id, var.pri_subnet_2_id, var.pri_subnet_3_id]
   scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  update_config {
    max_unavailable = 1
  }

  remote_access {
    ec2_ssh_key =                "new-key" #to allow ssh into nodes
  }
  
  instance_types = [ "c7i-flex.large" ]
}

resource "aws_iam_role" "gp_node_iam_role" {
  name = "gp_node_iam_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "gp_role_container_policy_attach" {
  policy_arn = data.aws_iam_policy.eks_ec2_container_policy.arn
  role       = aws_iam_role.gp_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "gp_role_eks_cni_policy_attach" {
  policy_arn = data.aws_iam_policy.eks_cni_policy.arn
  role       = aws_iam_role.gp_node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "gp_role_eks_worker_node_policy_attach" {
  policy_arn = data.aws_iam_policy.eks_worker_node_policy.arn
  role       = aws_iam_role.gp_node_iam_role.name
}
