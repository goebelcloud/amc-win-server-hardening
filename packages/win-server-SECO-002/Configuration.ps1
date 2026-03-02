<#
File: Configuration.ps1
Package: win-server-SECO-002 - Accounts: Guest account status
Purpose: Enforces local user account setting for: Accounts Guest account status.
Version: 1.0.0
#>

# win-server-SECO-002: Accounts: Guest account status
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Accounts: Guest account status = Disabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_002_Accounts_Guest_account_status {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script SECO_002 {
            GetScript  = {
                $user = Get-LocalUser | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                return @{ Result = @{
                  Name = $user.Name
                  Enabled = $user.Enabled
                } }
            }
            TestScript = {
                $user = Get-LocalUser -ErrorAction SilentlyContinue | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                if (-not $user) { return $false }
                return ($user.Enabled -eq $false)
            }
            SetScript  = {
                $user = Get-LocalUser | Where-Object { $_.SID.Value -match "-501`$" } | Select-Object -First 1
                if ($user) {
                  if ($false) { Enable-LocalUser -Name $user.Name } else { Disable-LocalUser -Name $user.Name }
                }
            }
        }
    }
}
