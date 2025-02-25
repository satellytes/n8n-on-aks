resource "azuread_application" "auth" {
  display_name     = "n8n-k8s-oauth2-proxy"
  sign_in_audience = "AzureADMyOrg" # Others are also supported

  owners = [data.azuread_client_config.current.object_id]
  web {
    redirect_uris = var.oauth_redirect_uris
  }
  // We don't specify any required API permissions - we allow user consent only
}

resource "azuread_service_principal" "sp" {
  client_id = azuread_application.auth.client_id
  app_role_assignment_required = false
}

resource "azuread_service_principal_password" "pass" {
  service_principal_id = azuread_service_principal.sp.id
}