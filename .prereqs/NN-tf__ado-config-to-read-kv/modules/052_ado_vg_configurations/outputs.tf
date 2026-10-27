output "ado_variable_group_id" {
  value = azuredevops_variable_group.ado_vargrp.id
}

output "ado_variable_group_name" {
  value = azuredevops_variable_group.ado_vargrp.name
}

output "ado_check_approval_id" {
  value = azuredevops_check_approval.ado_chkaprv_vg.id
}

output "ado_pipeline_authorization_ids_by_pipeline_name" {
  value = {
    for name, authorization in azuredevops_pipeline_authorization.ado_pipeauth_vg :
    name => authorization.id
  }
}
