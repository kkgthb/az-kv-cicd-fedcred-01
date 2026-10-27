Given "nonprod" & "prod" Entra Service Principal object ID inputs, "nonprod" & "prod" Azure subscription ID inputs, & "nonprod" & "prod" Azure Key Vault name inputs _(ahem -- still need to do that)_, and given a specific ADO org & project & Entra tenant as inputs, this will make sure that Azure Pipelines within the ADO project can connect to the Azure Key Vault resource.  _(And that they require approval to actually do so, and that certain pipelines are precleared to do so.)_

It's a pretty lazy script _(see comments scattered throughout)_ and isn't parameterized well enough for proper enterprise use.

But it's good enough to help me remember the various ADO configuration resources required to wire ADO to Azure Key Vault properly.
