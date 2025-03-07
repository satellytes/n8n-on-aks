# N8N on AKS

## Overview
This repository contains Infrastructure as Code (IaC) for deploying n8n workflow automation platform on a Kubernetes cluster in a highly scalable and resilient way. This setup uses Terraform and Helm to deploy the n8n application and the supporting services. The setup is designed for Azure Kubernetes Service (AKS).

> Though this repo provides a functional setup for deploying n8n on AKS it still must be adapted to your specific infrastructure requirements. It is not intended to be a production ready setup right out of the box. For additional security improvements see the [Recommended Improvements](#recommended-security-improvements) section.

## Architecture
The deployment consists of three main n8n components:
1. Main application server (not scalable in this setup)
2. Webhook server for handling incoming webhooks (scalable)
3. Worker nodes for processing tasks (scalable)

Each component is deployed as a separate Kubernetes deployment with shared configuration and storage.

## Key Components

### Infrastructure (Terraform)
- Sets up AKS cluster in Azure with basic node configuration
- Configures Azure AD integration for OAuth2 authentication
- Provisions necessary Azure resources including:
  - Resource Group
  - AKS Cluster
  - Azure AD Application for OAuth2
  - SSH keys for cluster access

### Kubernetes Resources (Helm)
The Helm chart deploys several key components:

1. **N8N Components**:
   - Main n8n application deployment
   - Webhook server deployment
   - Worker deployment for handling queue processing
   - Persistent volume claims for data storage

2. **Supporting Services**:
   - PostgreSQL database (can be local or external)
   - Redis for queue management
   - OAuth2 proxy for authentication
   - Nginx ingress controller
   - Cert-manager for SSL/TLS certificates

### Security Features
- OAuth2 authentication using Azure AD
- TLS encryption using Let's Encrypt certificates

### Configuration
The setup is configurable through:

```yaml
# Resources for n8n deployments
resources:
  requests:
    memory: "250Mi"
  limits:
    memory: "500Mi"

# Storage for n8n deployments
storage:
  size: 2Gi

# n8n configuration
n8n:
  protocol: http
  url: <url> # e.g. n8n.example.com
  encryptionKey: <encryption key> # python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
  env:
    timezone: Europe/Berlin
    redisHost: redis-master

service: # n8n service configuration
  port: 5678

oauth: # oauth configuration
  clientId: <client id>
  clientSecret: <client secret>
  cookieSecret: <cookie secret> # python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
  tenant: <tenant id>

workers: # worker scaling configuration
  replicas: 1

webhook: # webhook scaling configuration
  replicas: 1

postgres: # n8n postgres configuration
  deployment:
    local: "true" # local postgres deployment
    storage:
      size: 300Gi # postgres storage size
    adminCredentials: # postgres admin credentials these are generated by terraform
      secretName: postgres-secret
      userKey: POSTGRES_USER
      passwordKey: POSTGRES_PASSWORD
  host: postgres-service.n8n.svc.cluster.local # postgres host
  port: 5432 # postgres port
  database: n8n # postgres database
  credentials: # postgres credentials these are generated by terraform
    secretName: postgres-secret
    nonRootUserKey: POSTGRES_NON_ROOT_USER
    nonRootPasswordKey: POSTGRES_NON_ROOT_PASSWORD
```

### Database Setup
Includes options for both:
- Local PostgreSQL deployment within cluster
- External PostgreSQL connection support (not tested)

## How to deploy
1. Clone the repository
3. az login and select the correct subscription
2. cd into the `terraform` directory
4. Review variables in `terraform/variables.tf` and set the correct values especially cert_manager_email and oauth_redirect_uris
5. Run `terraform init`
6. Run `terraform apply`
7. After terraform we need to get some information from the deployment for the helm deployment. Run `terraform output -json` and note down the following values:
    - application_id
    - client_secret
8. cd into the `helm` directory
9. Open `values.yaml` and set the correct values for the variables
    - oauth.clientId -> application_id from terraform output
    - oauth.clientSecret -> client_secret from terraform output
    - oauth.cookieSecret -> python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
    - oauth.tenant -> tenant id from azure
    - n8n.url -> url of the n8n instance e.g. n8n.example.com
    - encryptionKey -> python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
10. Before we can deploy n8n we need to connect to the k8s cluster. Run `az aks get-credentials --resource-group <resource-group> --name n8n-k8s-aks-we`. If you changed these values in terraform you need to adapt this values accordingly
11. Ensure that you have the correct context and run `helm install n8n . -n n8n`. n8n namespace should not be changed here as there is already redis installed.
12. As a last step after the deployment is finished you need to set the ingress url to your n8n instance e.g. n8n.example.com. To get the ingress url run `k get ingress -n n8n`. The external ip is under `ADDRESS`. This ip need to be set in your domain provider (e.g. cloudflare) as an A record for your n8n instance.

## How to add new users
As additional security, this deployment uses oauth2 with Azure AD in front of the n8n website. The user that runs the Terraform deployment already is added to the Azure AD application. To add new users you need to add them as well. 

## Recommended (Security) Improvements (not implemented in this setup)
- Use a managed PostgreSQL service like Azure Database for PostgreSQL
- Use a managed Redis service like Azure Cache for Redis
- Private Cluster with Private DNS Zone
- Use Azure Key Vault for secret management with External Secrets Operator
- Ship metrics with OpenTelemetry and/or Prometheus and Grafana
- Add HPA for autoscaling the n8n pods dynamically (e.g. k8s or keda)
