# DECIDED FOR THIS DEMO:  If the calling `.yml` file told this `.ps1` file the the "username" secret's value 
# already by `.ps1` execution startup, then it will have done so under the variable name "THEUSERNAME".

# IMPORTANT:  PUT THIS BLOCK OF CODE FIRST!
$env_username_censored = $False
If ($env:TF_BUILD -eq "True") {
    Write-Host "This code is running inside Azure Pipelines."
    # First things first, let's make sure that this Azure Pipelines "job" 
    # censors the actual username value any time it sees it in logs from here on out!
    Write-Host "##vso[task.setvariable variable=MyMaskedSecret;issecret=true]([System.Environment]::GetEnvironmentVariable('THEUSERNAME'))"
    $env_username_censored = $True
}
ElseIf ($env:GITHUB_ACTIONS -eq "true") {
    Write-Host "This code is running inside GitHub Actions."
    # First things first, let's make sure that this GitHub Actions "job" 
    # censors the actual username value any time it sees it in logs from here on out!
    Write-Host "::add-mask::([System.Environment]::GetEnvironmentVariable('THEUSERNAME'))"
    $env_username_censored = $True
}
Else {
    Write-Host "This code is running on a local machine, inside a different CI/CD platform, etc.  Please do not echo, Write-Host, etc. the secret username, if you know it, because we did not set any censorship."
    $env_username_censored = $False
}

If (-Not $true) {
    # $env_username_censored) {
    # Short-circuit because logs not censored
    Write-Host "We are running in an environment that does not mask secrets in error logs.  We should stop."
}
Else {
    $env_unm = [System.Environment]::GetEnvironmentVariable('THEUSERNAME')
    If ($env_unm) {
        Write-Host "Looks like we already know the username; yay.  Let's take a look at its length."
        If ([string]::IsNullOrWhiteSpace($env_unm)) {
            Throw "The username was blank, but should not have been."
        }
        Write-Host "The length of the secret username is: $($env_unm.Length).  (I hope this is what you expected!)"
        Write-Host "Okay, ready?  These next commands, you should NOT normally run.  Under normal circumstances, sending the values of secrets to system output is a BAD thing!  However, for this demo ONLY, we want to show off that the censorship works."
        Write-Host "The value of the secret username is: $env_unm.  (I hope that you see this asterisked out!  If not, something went wrong with your CI/CD pipeline platform!  Stop and ask for help from a colleague.)"
    }
    Else {
        Write-Host("Looks like the CI/CD pipeline did not bother telling us the secret username.  Let's see if we can find it.")
        $azure_cli_command_string = 'az'
        $azure_cli_command_on_os = Get-Command $azure_cli_command_string -ErrorAction 'SilentlyContinue'
        $azure_cli_status = $null
        $az_error_details = $null
        $current_tenant_id = $null
        If ($null -eq $azure_cli_command_on_os) {
            $azure_cli_status = 'CliNotInstalled'
        }
        Else {
            $az_account_output = (& az account show --query 'tenantId' --output 'tsv' 2>&1)
            $az_exit_code = $LASTEXITCODE
            If ($az_exit_code -ne 0) {
                $az_error_details = ($az_account_output | Out-String).Trim()
                $azure_cli_status = 'AccountLookupFailed'
            }
            Else {
                $current_tenant_id = ($az_account_output | Out-String).Trim()
                If ([string]::IsNullOrWhiteSpace($current_tenant_id)) {
                    $current_tenant_id = $null
                    $azure_cli_status = 'TenantIdUnavailable'
                }
                Else {
                    $azure_cli_status = 'Ready'
                }
            }
        }
        If ($azure_cli_status -eq 'Ready') {
            Write-Host("Proceeding to try to fetch the username from Azure Key Vault.")
            az keyvault secret show --vault-name 'TODO' --name 'username'
        }
    }
}

