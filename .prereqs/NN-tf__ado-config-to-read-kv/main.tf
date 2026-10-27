# ----------- Entra tenant auth spot-check ------------
data "azuread_client_config" "current_entra_context" {
  provider = azuread.demo
  lifecycle {
    postcondition {
      condition     = self.tenant_id == var.entra_tenant_id
      error_message = "We are not logged into Entra as expected."
    }
  }
}

# ----------- ADO org auth spot-check ------------
data "azuredevops_client_config" "current_ado_context" {
  provider = azuredevops.demo
  lifecycle {
    postcondition {
      condition     = self.tenant_id == var.entra_tenant_id
      error_message = "We are not logged into ADO as expected."
    }
  }
}

# ----------- ADO project data spot-check ------------
data "azuredevops_project" "the_ado_project" {
  provider = azuredevops.demo
  name     = var.ado_project_name
  lifecycle {
    postcondition {
      condition     = self.name == var.ado_project_name
      error_message = "The project data was not fetched out of ADO"
    }
  }
}

# ----------- ADO identity translations ------------
module "ado_012_current_user_id" {
  depends_on = [data.azuread_client_config.current_entra_context]
  source     = "./modules/012_get_ado_user_id_by_entra_id"
  providers = {
    azuredevops = azuredevops.demo
  }
  entra_user_object_id = data.azuread_client_config.current_entra_context.object_id
}
module "ado_014_gatekeepers_group_id" {
  depends_on = [data.azuread_client_config.current_entra_context]
  source     = "./modules/014_get_ado_group_id_by_display_name"
  providers = {
    azuredevops = azuredevops.demo
  }
  entra_group_display_name = var.entra_gatekeepers_group_display_name
}

# ----------- ADO existing pipelines data ------------
module "ado_022_preapproved_pipeline_ids" {
  depends_on = [data.azuread_client_config.current_entra_context]
  source     = "./modules/022_get_ado_pipeline_id_or_ids_not_sure_yet"
  providers = {
    azuredevops = azuredevops.demo
  }
  ado_project_id     = data.azuredevops_project.the_ado_project.id
  ado_pipeline_names = var.ado_preapproved_pipeline_names
}

# ----------- ADO configure the nonprod service connection and variable group ------------
module "ado_042_ado_sc_nonprod" {
  depends_on = [module.ado_014_gatekeepers_group_id, module.ado_022_preapproved_pipeline_ids]
  source     = "./modules/042_ado_sc_configurations"
  providers = {
    azuread     = azuread.demo
    azuredevops = azuredevops.demo
    azurerm     = azurerm.demo_nonprod_az_subscription
  }
  ado_project_id        = data.azuredevops_project.the_ado_project.id
  entra_sp_display_name = var.entra_kvsu_sp_display_name_nonprod
  env_nickname          = "nonprod"
  # Note:  In the real world, maybe we'd have different nonprod vs. prod approvers.
  gatekeepers_group_id = module.ado_014_gatekeepers_group_id.ado_id_for_entra_group
  # Note:  In the real world, maybe the pipelines using nonprod vs. prod differ.
  permitted_pipeline_ids_by_name = module.ado_022_preapproved_pipeline_ids.ado_pipeline_ids_by_name
}
module "ado_052_ado_vg_nonprod" {
  depends_on = [module.ado_042_ado_sc_nonprod]
  source     = "./modules/052_ado_vg_configurations"
  providers = {
    azuredevops = azuredevops.demo
  }
  ado_project_id = data.azuredevops_project.the_ado_project.id
  # I don't think the fact that I was too lazy to actually create any key vaults yet 
  # is going to bite me until I leave plan mode...
  az_kv_name                = "TODO"
  env_nickname              = "nonprod"
  ado_service_connection_id = module.ado_042_ado_sc_nonprod.ado_service_connection_id
  # Note:  In the real world, maybe we'd have different nonprod vs. prod approvers.
  gatekeepers_group_id = module.ado_014_gatekeepers_group_id.ado_id_for_entra_group
  # Note:  In the real world, maybe the pipelines using nonprod vs. prod differ.
  permitted_pipeline_ids_by_name = module.ado_022_preapproved_pipeline_ids.ado_pipeline_ids_by_name
}

# ----------- ADO configure the prod service connection and variable group ------------
module "ado_042_ado_sc_prod" {
  depends_on = [module.ado_014_gatekeepers_group_id, module.ado_022_preapproved_pipeline_ids]
  source     = "./modules/042_ado_sc_configurations"
  providers = {
    azuread     = azuread.demo
    azuredevops = azuredevops.demo
    azurerm     = azurerm.demo_prod_az_subscription
  }
  ado_project_id        = data.azuredevops_project.the_ado_project.id
  entra_sp_display_name = var.entra_kvsu_sp_display_name_prod
  env_nickname          = "prod"
  # Note:  In the real world, maybe we'd have different nonprod vs. prod approvers.
  gatekeepers_group_id = module.ado_014_gatekeepers_group_id.ado_id_for_entra_group
  # Note:  In the real world, maybe the pipelines using nonprod vs. prod differ.
  permitted_pipeline_ids_by_name = module.ado_022_preapproved_pipeline_ids.ado_pipeline_ids_by_name
}
module "ado_052_ado_vg_prod" {
  depends_on = [module.ado_042_ado_sc_prod]
  source     = "./modules/052_ado_vg_configurations"
  providers = {
    azuredevops = azuredevops.demo
  }
  ado_project_id = data.azuredevops_project.the_ado_project.id
  # I don't think the fact that I was too lazy to actually create any key vaults yet 
  # is going to bite me until I leave plan mode...
  az_kv_name                = "TODO"
  env_nickname              = "prod"
  ado_service_connection_id = module.ado_042_ado_sc_prod.ado_service_connection_id
  # Note:  In the real world, maybe we'd have different prod vs. prod approvers.
  gatekeepers_group_id = module.ado_014_gatekeepers_group_id.ado_id_for_entra_group
  # Note:  In the real world, maybe the pipelines using prod vs. prod differ.
  permitted_pipeline_ids_by_name = module.ado_022_preapproved_pipeline_ids.ado_pipeline_ids_by_name
}
