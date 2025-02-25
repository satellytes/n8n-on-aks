resource random_password postgres_password {
  length = 24
}
resource random_password postgres_admin_password {
  length = 24
}

# create namespace for cert mananger
resource "kubernetes_namespace" "n8n" {
  metadata {
    labels = {
      "name" = "n8n"
    }
    name = "n8n"
  }
}


resource "kubernetes_secret" "postgres" {
  metadata {
    name = "postgres-secret"
    namespace = "n8n"
  }

  data = {
    POSTGRES_USER = "admin"
    POSTGRES_PASSWORD = random_password.postgres_admin_password.result
    POSTGRES_NON_ROOT_USER = "postgres"
    POSTGRES_NON_ROOT_PASSWORD = random_password.postgres_password.result
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.n8n]
}