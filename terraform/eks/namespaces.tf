resource "kubernetes_namespace" "db_ns" {
  metadata {
    name = "db-ns"
  }
}
resource "kubernetes_namespace" "back_ns" {
  metadata {
    name = "back-ns"
  }
}

resource "kubernetes_namespace" "front_ns" {
  metadata {
    name = "front-ns"
  }
}

resource "null_resource" "nginx-conf-index-cm-creator" {
  depends_on = [ kubernetes_namespace.back_ns ]
  provisioner "local-exec" {
    command = <<-EOF
    aws eks update-kubeconfig --name iti-gp-cluster --region us-east-1
    kubectl create configmap nginx-conf --from-file=./nginx.conf -n back-ns
    kubectl create configmap index --from-file=./index.html -n back-ns
    EOF
  }
}