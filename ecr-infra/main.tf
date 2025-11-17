provider "aws" {
  region = "us-east-1"
}

#ecr registry
resource "aws_ecr_repository" "backend" {
  name = "iti-gp-image"
  force_delete = true
}

resource "null_resource" "backend_image_pusher" {
  depends_on = [ aws_ecr_repository.backend ]

  provisioner "local-exec" {
    command = <<-EOF
      docker push 910148268074.dkr.ecr.us-east-1.amazonaws.com/iti-gp-image:latest
    EOF
  }
}