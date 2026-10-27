This repo demonstrates what it looks like to get a CI/CD pipeline, such as a GitHub Actions workflow, or an _(Azure DevOps "ADO")_ Azure Pipelines pipeline, securely querying values out of Azure Key Vault.

In this demo, there are 3 Key Vaults -- one for `dev`, one for `stg`, and one for `prd` -- containing 2 secrets _(`username` and `password`)_ apiece.

[Since February 2021](https://learn.microsoft.com/en-us/azure/key-vault/general/whats-new#february-2021), it's been possible to grant the Azure RBAC role named `Key Vault Secrets User` to an individual secret, so I probably could get away with 1 Key Vault containing 6 secrets _(`dev_username`, `dev_password`, `stg_username`, etc.)_.  However, Azure DevOps's notion of a [key-vault-linked Variable Group](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/link-variable-groups-to-key-vaults) _([ADO REST API docs](https://learn.microsoft.com/en-us/rest/api/azure/devops/distributedtask/variablegroups?view=azure-devops-rest-7.0); [Terraform `azuredevops_variable_group` docs](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/variable_group))_ can only work with Entra principals that have been granted `Key Vault Secrets User` against an entire Vault, and obviously, for privilege separation / the principal of least privilege, you wouldn't want just one ADO Variable Group to be able to see all 6 passwords, so I think it's worth paying for 3 Key Vaults.  ADO key-vault-linked Variable Groups help auto-censor the values of secrets in Azure Pipelines logs, so that you don't have to remember to do that manually in your CI/CD pipeline code yourself, which I think is just a _massive_ value-add.  Provisioning a few extra Key Vaults is cheap compared to a secrets leak!

TODO:  actually flesh this out.  10/27/2026, 1PM

## Related links

* [Katie Kodes:  "Variables and secrets for CI/CD pipelines"](https://katiekodes.com/adop-gha-variables-secrets)