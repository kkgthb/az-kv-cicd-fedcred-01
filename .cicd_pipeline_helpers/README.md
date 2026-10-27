TODO:  Put some PowerShell scripts here that OIDC into Azure Key Vault and `Write-Host()` the `.Length` of the value of `username`.

Make sure the scripts "mask" secrets appropriately any time they end up fetched from something like the `az kv` CLI command.

_(No need if fetching them straight out of an ADO Variable Group, though, on Azure Pipelines.  It's more of just a thing you need to worry about with GitHub Actions, or with Azure Pipelines when using things like `az kv` instead of using ADO Variable Groups.)_

TODO:  Create 1 2-stage Azure Pipelines `.yaml` file, and 1 2-stage GitHub Actions `.yaml` file, demonstrating invoking this within a task that's OIDC-authenticated into an appropriate Entra Service Principal.
* See https://github.com/kkgthb/gh-actions-deploy-web-to-azure/ for an example I've done before.
* Keep going with other git-forge-hosted CI/CD platforms if I feel like it.  _(Though honestly, I probably won't.)_
