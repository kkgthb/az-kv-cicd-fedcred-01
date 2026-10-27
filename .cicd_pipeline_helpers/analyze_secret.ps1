# DECIDED FOR THIS DEMO:  If the calling `.yml` file told this `.ps1` file the the "username" secret's value 
# already by `.ps1` execution startup, then it will have done so under the variable name "THEUSERNAME".

Write-Host("")
Write-Host("")



$env_based_unm_length = (([System.Environment]::GetEnvironmentVariable('THEUSERNAME')).Length) # Hopefully ".Length" won't be a "process that errors out irresponsibly," since we haven't necessarily masked yet.
$env_username_is_censored = $False # Initialize default value
# BEGIN ENV-USERNAME MASKER CODE BLOCK
If ([System.Environment]::GetEnvironmentVariable('TF_BUILD') -eq "True") {
    Write-Host "This code is running inside Azure Pipelines."
    # Force Azure Pipelines to treat this as a secret, period, for the rest of the Job.
    # (Will reset to visible next Job, though.)
    # IMPORTANT:  adding the mask should come first before anything anything anything anything anything else.
    Write-Host "##vso[task.setsecret]([System.Environment]::GetEnvironmentVariable('THEUSERNAME'))"
    $env_username_is_censored = $True
    # (Though note:  this might be redundant to what Azure Pipelines variable group secrets already did.
    # But better safe than sorry.)
}
ElseIf ([System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -eq "true") {
    Write-Host "This code is running inside GitHub Actions."
    # Force GitHub Actions to treat this as a secret, period, for the rest of the Job.
    # (Will reset to visible next Job, though.)
    # IMPORTANT:  adding the mask should come first before anything anything anything anything anything else.
    Write-Host "::add-mask::([System.Environment]::GetEnvironmentVariable('THEUSERNAME'))"
    $env_username_is_censored = $True
    # (Though note:  this might be redundant to what GitHub Actions secrets already did.
    # But better safe than sorry.)
}
Else {
    Write-Host "This code is running on a local machine, inside a different CI/CD platform, etc.  Please do not echo, Write-Host, etc. the secret username, if you know it, because we did not set any censorship."
    $env_username_is_censored = $False
}
# END ENV-USERNAME MASKER CODE BLOCK
Write-Host "The length of the secret username from variable injection is: $($env_based_unm_length).  (I hope this is what you expected!)"
If ($env_username_is_censored) {
    Write-Host "Okay, ready?  This next command, you should NOT normally run.  Under normal circumstances, sending the values of secrets to system output is a BAD thing!  However, for this demo ONLY, we want to show off that the censorship works."
    Write-Host "The value of the secret username from variable injection is: $([System.Environment]::GetEnvironmentVariable('THEUSERNAME')).  (I hope that you see this asterisked out!  If not, something went wrong with your CI/CD pipeline platform!  Stop and ask for help from a colleague.)"
}
Else {
    Write-Host "Not writing out value of the secret username from variable injection because this runtime cannot mask it safely."
}
# BEGIN ENV-USERNAME CLEANUP
[System.Environment]::SetEnvironmentVariable('THEUSERNAME', $null, 'Process')
[System.Environment]::SetEnvironmentVariable('THEUSERNAME', $null, 'User')
$env_username_is_censored = $False
$env_based_unm_length = 0
# END ENV-USERNAME CLEANUP



Write-Host("")
Write-Host("")
# TODO:  figure out if GitHub Actions injects variables a little differently.  Might need to do literals, too?  Can't remember.
# Maybe it is just ENV injection when calling a PowerShell script FILE.
# That'd be nice, so I wouldn't have to write even more code.



Write-Host("Let's also see masking with Azure Key Vault, where it is NEVER redundant and ALWAYS required.")
$az_accounts_module = Get-Module -ListAvailable -Name 'Az.Accounts' | Select-Object -First 1
$az_keyvault_module = Get-Module -ListAvailable -Name 'Az.KeyVault' | Select-Object -First 1
$azure_powershell_status = $null
$azure_powershell_error_details = $null
$current_tenant_id = $null
$az_unm_ss = $null
If ($null -eq $az_accounts_module) {
    $azure_powershell_status = 'AzAccountsModuleNotInstalled'
}
ElseIf ($null -eq $az_keyvault_module) {
    $azure_powershell_status = 'AzKeyVaultModuleNotInstalled'
}
Else {
    Try {
        Import-Module 'Az.Accounts' -ErrorAction 'Stop'
        Import-Module 'Az.KeyVault' -ErrorAction 'Stop'
        $azure_context = Get-AzContext -ErrorAction 'Stop'
        If ($null -eq $azure_context) {
            $azure_powershell_status = 'NotSignedIn'
        }
        Else {
            $current_tenant_id = $azure_context.Tenant.Id
            If ([string]::IsNullOrWhiteSpace($current_tenant_id)) {
                $azure_powershell_status = 'TenantIdUnavailable'
            }
            Else {
                Try {
                    $username_key_vault_secret = Get-AzKeyVaultSecret -VaultName 'TODO' -Name 'TODO' -ErrorAction 'Stop'
                    $az_unm_ss = $username_key_vault_secret.SecretValue
                    If ($az_unm_ss -is [System.Security.SecureString]) {
                        $azure_powershell_status = 'Ready'
                    }
                    Else {
                        $az_unm_ss = $null
                        $azure_powershell_status = 'SecretValueUnavailable'
                    }
                }
                Catch {
                    $azure_powershell_error_details = $_.Exception.Message
                    $azure_powershell_status = 'SecretRetrievalFailed'
                }
            }
        }
    }
    Catch {
        $azure_powershell_error_details = $_.Exception.Message
        $azure_powershell_status = 'AzurePowerShellUnavailable'
    }
}
If (-not ($azure_powershell_status -eq 'Ready')) {
    Throw "Something went wrong with fetching the username from Azure Key Vault.  Hint:  $azure_powershell_status"
}
Write-Host("Retrieved the username from Azure Key Vault as a SecureString.")
Write-Host("")
$az_based_unm_length = ($az_unm_ss.Length) # ".Length" against a secure string already presumably doesn't risk leaking out the value even if it errors out, yay.
$az_username_is_censored = $False # Initialize default value
# BEGIN AZ-KV-USERNAME MASKER CODE BLOCK
If ([System.Environment]::GetEnvironmentVariable('TF_BUILD') -eq "True") {
    Write-Host "This code is running inside Azure Pipelines."
    # Force Azure Pipelines to treat this as a secret, period, for the rest of the Job.
    # (Will reset to visible next Job, though.)
    # IMPORTANT:  adding the mask should come first before anything anything anything anything anything else.
    Write-Host "##vso[task.setsecret](ConvertFrom-SecureString -AsPlainText -SecureString ($az_unm_ss))"
    $az_username_is_censored = $True
    # (Though note:  this might be redundant to what Azure Pipelines variable group secrets already did.
    # But better safe than sorry.)
}
ElseIf ([System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -eq "true") {
    Write-Host "This code is running inside GitHub Actions."
    # Force GitHub Actions to treat this as a secret, period, for the rest of the Job.
    # (Will reset to visible next Job, though.)
    # IMPORTANT:  adding the mask should come first before anything anything anything anything anything else.
    Write-Host "::add-mask::(ConvertFrom-SecureString -AsPlainText -SecureString ($az_unm_ss))"
    $az_username_is_censored = $True
    # (Though note:  this might be redundant to what GitHub Actions secrets already did.
    # But better safe than sorry.)
}
Else {
    Write-Host "This code is running on a local machine, inside a different CI/CD platform, etc.  Please do not echo, Write-Host, etc. the secret username, if you know it, because we did not set any censorship."
    $az_username_is_censored = $False
}
# END AZ-KV-USERNAME MASKER CODE BLOCK
Write-Host "The length of the secret username from Azure Key Vault is: $($az_based_unm_length).  (I hope this is what you expected!)"
If ($az_username_is_censored) {
    Write-Host "Okay, ready?  This next command, you should NOT normally run.  Under normal circumstances, sending the values of secrets to system output is a BAD thing!  However, for this demo ONLY, we want to show off that the censorship works."
    Write-Host "The value of the secret username from Azure Key Vault is: $(ConvertFrom-SecureString -AsPlainText -SecureString ($az_unm_ss)).  (I hope that you see this asterisked out!  If not, something went wrong with your CI/CD pipeline platform!  Stop and ask for help from a colleague.)"
}
Else {
    Write-Host "Not writing out value of the secret username from Azure Key Vault because this runtime cannot mask it safely."
}
# BEGIN AZ-KV-USERNAME CLEANUP
$az_unm_ss = $Null
$username_key_vault_secret = $Null
$az_username_is_censored = $False
$az_based_unm_length = 0
# END AZ-KV-USERNAME CLEANUP
