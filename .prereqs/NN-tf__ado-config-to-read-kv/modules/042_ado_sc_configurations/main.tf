data "azurerm_subscription" "az_sub" {
  lifecycle {
    postcondition {
      condition     = (coalesce(self.tenant_id, "") != "")
      error_message = "AzureRM tenant ID is blank."
    }
  }
}

data "azuread_application" "entra_appreg" {
  display_name = var.entra_sp_display_name
}

resource "azuredevops_serviceendpoint_azurerm" "ado_svccnxn" {
  project_id = var.ado_project_id
  # I think I might already have one like this in the tenant I'm playing with, so threw in "MyDemo"
  # Also, the env nickname would be redundant if I weren't being lazy and using the same Entra Service Principal 
  # twice as if it were two separate service principals while I get this code working.
  service_endpoint_name                  = "SC-MyDemo-${var.env_nickname}-${var.entra_sp_display_name}"
  description                            = "Represents CI/CD when authenticating into ${var.env_nickname} as ${var.entra_sp_display_name}."
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = data.azurerm_subscription.az_sub.tenant_id
  azurerm_subscription_id                = data.azurerm_subscription.az_sub.subscription_id
  azurerm_subscription_name              = data.azurerm_subscription.az_sub.display_name
  credentials {
    serviceprincipalid = data.azuread_application.entra_appreg.client_id
  }
}

resource "azuread_application_federated_identity_credential" "entra_fedcreds" {
  application_id = data.azuread_application.entra_appreg.id
  display_name   = "CICD-ADO-${azuredevops_serviceendpoint_azurerm.ado_svccnxn.service_endpoint_name}"
  description    = "Represents the \"${azuredevops_serviceendpoint_azurerm.ado_svccnxn.service_endpoint_name}\" Azure Pipelines CI/CD service connection."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azuredevops_serviceendpoint_azurerm.ado_svccnxn.workload_identity_federation_issuer
  subject        = azuredevops_serviceendpoint_azurerm.ado_svccnxn.workload_identity_federation_subject
}

resource "azuredevops_check_approval" "ado_chkaprv_sc" {
  # To prevent accidents and slow down hackers, 
  # lock down the ADO service connection's use by requiring at least 1 manual human approval 
  # (a 2nd person -- not the person who caused the CI/CD pipeline to run)
  # each time Azure Pipelines tries to authenticate into cloud resource as it.
  project_id                 = var.ado_project_id
  target_resource_type       = "endpoint"
  target_resource_id         = azuredevops_serviceendpoint_azurerm.ado_svccnxn.id
  minimum_required_approvers = 1
  requester_can_approve      = false
  timeout                    = 60
  approvers                  = [var.gatekeepers_group_id]
}

resource "azuredevops_pipeline_authorization" "ado_pipeauth_sc" {
  # For the specified pipelines, this ensures no one has to approve 
  # using this service connection on the specified YAML pipeline's first run.
  # (Note:  the runner of this Terraform code must have appropriate privileges against that specific 
  # ADO service connection resource, just like manual button-clickers would need.)
  for_each    = var.permitted_pipeline_ids_by_name
  project_id  = var.ado_project_id
  type        = "endpoint"
  resource_id = azuredevops_serviceendpoint_azurerm.ado_svccnxn.id
  pipeline_id = each.value
}
