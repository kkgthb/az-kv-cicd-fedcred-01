# DECIDED FOR THIS DEMO:  If the calling `.yml` file told this `.ps1` file the the "username" secret's value 
# already by `.ps1` execution startup, then it will have done so under the variable name "THEUSERNAME".

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
