#to use inside pipeline
output "ecr_repo_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.backend.name}"
}