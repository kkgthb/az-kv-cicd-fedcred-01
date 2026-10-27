variable "workload_nickname" {
  type     = string
  nullable = false
}

variable "entra_tenant_id" {
  type     = string
  nullable = false
}

variable "entra_kvsu_sp_display_name_nonprod" {
  description = "This Entra Service Principal should have been assigned \"Key Vault Secrets User\" against the nonprod Key Vault.  Obviously, it should be a totally separate service principal from the one with KVSU against prod."
  type        = string
  nullable    = false
}

variable "entra_kvsu_sp_display_name_prod" {
  description = "This Entra Service Principal should have been assigned \"Key Vault Secrets User\" against the prod Key Vault.  Obviously, it should be a totally separate service principal from the one with KVSU against nonprod."
  type        = string
  nullable    = false
}

variable "ado_organization_url" {
  type     = string
  nullable = false
}

variable "ado_project_name" {
  type     = string
  nullable = false
}

variable "entra_gatekeepers_group_display_name" {
  type     = string
  nullable = false
}

variable "ado_preapproved_pipeline_names" {
  type = list(string)
  validation {
    condition = alltrue([
      for nm in var.ado_preapproved_pipeline_names : nm != ""
    ])
    error_message = "No preapproved pipeline name may be blank."
  }
}

variable "az_sub_id_nonprod" {
  description = "This Azure subscription should contain the nonprod Key Vault."
  type        = string
  nullable    = false
}

variable "az_sub_id_prod" {
  description = "This Azure subscription should contain the prod Key Vault."
  type        = string
  nullable    = false
}
