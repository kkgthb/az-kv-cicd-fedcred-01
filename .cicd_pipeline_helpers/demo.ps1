# DECIDED FOR THIS DEMO:  If the calling `.yml` file told this `.ps1` file the the "username" secret's value 
# already by `.ps1` execution startup, then it will have done so under the variable name "THEUSERNAME".



$env_based_unm_length_was = 0 # Initialize default value



$env_username_is_censored = $False # Initialize default value
$env_based_unm = [System.Environment]::GetEnvironmentVariable('THEUSERNAME')

If ($env_based_unm) {
    # BEGIN MASKER CODE BLOCK
    If ([System.Environment]::GetEnvironmentVariable('TF_BUILD') -eq "True") {
        Write-Host "This code is running inside Azure Pipelines."
        # Validate whether Azure Pipelines already knows this is a secret.
        # To do so, first we write it into a localized, captured text variable instead of stdout.
        # (This particular snippet redirects standard host output to an in-memory string variable.)
        $unmOutputCheck = Invoke-Expression "Write-Output '$env_based_unm'"
        # And then we test if the Azure Pipeline log-scrubber intercepted and masked it.
        # IMPORTANT:  validating the mask should come first before anything anything anything anything anything else.
        If ($unmOutputCheck -contains "***" -or $unmOutputCheck -eq "***") {
            Write-Host "Verification: The runtime has ALREADY flagged this the username's value as a secret.  Yay."
            $env_username_is_censored = $True
        }
        # If not, we fail this whole `.ps1` file.  Please go back and reconfigure your Azure Pipelines / ADO setup.
        Else {
            Write-Warning "CRITICAL: This value is in PLAIN TEXT. Subsequent tasks/steps can read it."
            $env_username_is_censored = $False
            # We don't necessarily want to use "VSO" "task.setvariable" because we probably DON'T want 
            # this secret available to every subsequent task in the Azure Pipelines job currently running.
            # It's probably best to keep it so subsequent task calls, which might involve 
            # untrusted 3rd-party dependencies, can't read it.
            Throw "Azure Pipelines job halted: injected username variable was not flagged secret before injection!"
        }
    }
    ElseIf ([System.Environment]::GetEnvironmentVariable('GITHUB_ACTIONS') -eq "true") {
        Write-Host "This code is running inside GitHub Actions."
        # Force GitHub Actions to treat this as a secret, period.
        # Yay, much easier than Azure Pipelines VSO variable setting weirdness.
        # IMPORTANT:  adding the mask should come first before anything anything anything anything anything else.
        Write-Host "::add-mask::([System.Environment]::GetEnvironmentVariable('THEUSERNAME'))"
        $env_username_is_censored = $True
    }
    Else {
        Write-Host "This code is running on a local machine, inside a different CI/CD platform, etc.  Please do not echo, Write-Host, etc. the secret username, if you know it, because we did not set any censorship."
        $env_username_is_censored = $False
    }
    # END MASKER CODE BLOCK
    # Okay, let's check it out, if it's safe to do so (that is, if we're masked)
    If ($env_username_is_censored) {
        Write-Host "Looks like we are safe to inspect the username."
        If ([string]::IsNullOrWhiteSpace($env_based_unm)) {
            Throw "The username was blank, but should not have been."
        }
        $env_based_unm_length_was = $env_based_unm.Length # We'll need this later anyway
        Write-Host "The length of the secret username is: $($env_based_unm_length_was).  (I hope this is what you expected!)"
        Write-Host "Okay, ready?  These next commands, you should NOT normally run.  Under normal circumstances, sending the values of secrets to system output is a BAD thing!  However, for this demo ONLY, we want to show off that the censorship works."
        Write-Host "The value of the secret username is: $env_based_unm.  (I hope that you see this asterisked out!  If not, something went wrong with your CI/CD pipeline platform!  Stop and ask for help from a colleague.)"
    }
    Else {
        Write-Host "Sorry, not going to run the test -- we're not really safe to be writing the secret username to system output since we aren't running in an auto-masking context, nor are we safe to pass the value to any other process that might be programmed badly and leak the value into system output, since, again, we do not have auto-masking working properly."
    }
}
Else {
    Write-Host "No need to test the length of our env-based username -- the value is simply not set at all on this OS this way, it seems."
}
# BEGIN ENV CLEANUP
$env_based_unm = $Null
[System.Environment]::SetEnvironmentVariable('THEUSERNAME', $null, 'Process')
[System.Environment]::SetEnvironmentVariable('THEUSERNAME', $null, 'User')
$env_username_is_censored = $False
# Deliberately don't reset $env_based_unm_length_was yet
# END ENV CLEANUP



If ($env_based_unm_length_was -gt 0) {
    Write-Host "No need to query Azure Key Vault -- clearly we securely found the username in another way."
}
Else {
    Write-Host("Looks like the CI/CD pipeline did not bother telling us the secret username.  Let's see if we can find it in Azure Key Vault.")
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
                        $username_key_vault_secret = Get-AzKeyVaultSecret -VaultName 'TODO' -Name 'username' -ErrorAction 'Stop'
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
    If ($azure_powershell_status -eq 'Ready') {
        Write-Host("Retrieved the username from Azure Key Vault as a SecureString.")
        $az_username_censored = $False
        If ($env:TF_BUILD -eq "True") {
            Write-Host "This code is running inside Azure Pipelines."
            # Right away, let's make sure that this Azure Pipelines "job" 
            # censors the actual username value any time it sees it in logs from here on out!
            # Note:  annoyingly, the value also becomes available to every subsequent task in the job 
            # as a job-level variable by the name mentioned in "variable=".
            # There doesn't seem to be a generic masker, sadly.
            # That's frustrating, because it'd be nice to imagine that a corrupted task 
            # wouldn't have access to this secret value.
            # ANYWAY, well, we wouldn't even need to do this masking
            Write-Host "##vso[task.setvariable variable=AnyMemorableStringHereWillDoNumberTwo;issecret=true](ConvertFrom-SecureString -AsPlainText -SecureString ($az_unm_ss))"
            $az_username_censored = $True
        }
        ElseIf ($env:GITHUB_ACTIONS -eq "true") {
            Write-Host "This code is running inside GitHub Actions."
            # Right away, let's make sure that this GitHub Actions "job" 
            # censors the actual username value any time it sees it in logs from here on out!
            Write-Host "::add-mask::(ConvertFrom-SecureString -AsPlainText -SecureString ($az_unm_ss))"
            $az_username_censored = $True
        }
        Else {
            Write-Host "This code is running on a local machine, inside a different CI/CD platform, etc.  Please do not echo, Write-Host, etc. the secret username, if you know it, because we did not set any censorship."
            $az_username_censored = $False
        }
    }
}


