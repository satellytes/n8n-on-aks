# Install cert-manager helm chart using terraform
resource "helm_release" "redis" {
  name       = "redis"
  chart      = "oci://registry-1.docker.io/bitnamicharts/redis"
  version    = "20.7.0"
  namespace  = kubernetes_namespace.n8n.metadata.0.name

  set {
    name = "replica.replicaCount"
    value = "1" # For testing we want less replicas
  }

  depends_on = [
    kubernetes_namespace.n8n
  ]
}