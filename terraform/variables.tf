variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "n8n-k8s-test-rg"
}

variable "resource_group_location" {
  type        = string
  default     = "westeurope"
  description = "Location of the resource group."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 2
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "cert_manager_email" {
  type        = string
  description = "Email address for Let's Encrypt notifications"
  default     = "your-email@example.com"
}

variable "oauth_redirect_uris" {
  type        = list(string)
  description = "List of allowed OAuth redirect URIs"
  default     = ["https://yourdomain.com/oauth2/callback"]
}



