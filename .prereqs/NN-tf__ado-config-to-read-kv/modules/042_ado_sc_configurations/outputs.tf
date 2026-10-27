output "ado_service_connection_id" {
  value = azuredevops_serviceendpoint_azurerm.ado_svccnxn.id
}

output "ado_service_connection_name" {
  value = azuredevops_serviceendpoint_azurerm.ado_svccnxn.service_endpoint_name
}

output "entra_federated_identity_credential_id" {
  value = azuread_application_federated_identity_credential.entra_fedcreds.id
}

output "entra_federated_identity_credential_display_name" {
  value = azuread_application_federated_identity_credential.entra_fedcreds.display_name
}

output "ado_check_approval_id" {
  value = azuredevops_check_approval.ado_chkaprv_sc.id
}

output "ado_pipeline_authorization_ids_by_pipeline_name" {
  value = {
    for name, authorization in azuredevops_pipeline_authorization.ado_pipeauth_sc :
    name => authorization.id
  }
}
