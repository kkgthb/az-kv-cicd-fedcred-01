resource "azuredevops_variable_group" "ado_vargrp" {
  # Note:  this and its dependencies will fail if anyone forgot to create 
  # the "username" or "password" Secret-typed resources on each KV.
  project_id = var.ado_project_id
  # I think I might already have one like this in the tenant I'm playing with, so threw in "MyDemo"
  # Also, the env nickname would be redundant if I weren't being lazy and using the same Entra Service Principal 
  # twice as if it were two separate service principals while I get this code working.
  name         = "VG-KV-MyDemo-${var.env_nickname}-${var.az_kv_name}"
  description  = "Variable group linked to \"${var.az_kv_name}\" (${var.env_nickname}) Azure Key Vault secrets."
  allow_access = false
  key_vault {
    name                = var.az_kv_name
    service_endpoint_id = var.ado_service_connection_id
    search_depth        = 0
  }
  variable {
    name = "username"
  }
  variable {
    name = "password"
  }
}

resource "azuredevops_check_approval" "ado_chkaprv_vg" {
  # To prevent accidents and slow down hackers, 
  # lock down the ADO variable group's use by requiring at least 1 manual human approval 
  # (a 2nd person -- not the person who caused the CI/CD pipeline to run)
  # each time Azure Pipelines tries to read secrets from it.
  project_id                 = var.ado_project_id
  target_resource_type       = "variablegroup"
  target_resource_id         = azuredevops_variable_group.ado_vargrp.id
  minimum_required_approvers = 1
  requester_can_approve      = false
  timeout                    = 60
  approvers                  = [var.gatekeepers_group_id]
}

resource "azuredevops_pipeline_authorization" "ado_pipeauth_vg" {
  # For the specified pipelines, this ensures no one has to approve 
  # using this variable group on the specified YAML pipeline's first run.
  # (Note:  the runner of this Terraform code must have appropriate privileges against that specific 
  # ADO variable group resource, just like manual button-clickers would need.)
  for_each    = var.permitted_pipeline_ids_by_name
  project_id  = var.ado_project_id
  type        = "variablegroup"
  resource_id = azuredevops_variable_group.ado_vargrp.id
  pipeline_id = each.value
}
