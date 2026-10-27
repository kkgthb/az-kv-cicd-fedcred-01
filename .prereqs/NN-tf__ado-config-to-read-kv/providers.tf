provider "azuread" {
  alias     = "demo"
  tenant_id = var.entra_tenant_id
  use_cli   = true
}

provider "azuredevops" {
  alias           = "demo"
  org_service_url = var.ado_organization_url
  use_cli         = true # Log into Azure DevOps as whoever is currently logged in within the Azure CLI
}

provider "azurerm" {
  features {}
  alias                           = "demo_nonprod_az_subscription"
  tenant_id                       = var.entra_tenant_id
  subscription_id                 = var.az_sub_id_nonprod
  resource_provider_registrations = "none"
}

provider "azurerm" {
  features {}
  alias                           = "demo_prod_az_subscription"
  tenant_id                       = var.entra_tenant_id
  subscription_id                 = var.az_sub_id_prod
  resource_provider_registrations = "none"
}
