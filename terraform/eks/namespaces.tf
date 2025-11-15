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