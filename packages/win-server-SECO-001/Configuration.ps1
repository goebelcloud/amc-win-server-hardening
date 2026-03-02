<#
File: Configuration.ps1
Package: win-server-SECO-001 - Accounts Limit local account use of blank passwords to conso
Purpose: Enforces a Windows security hardening registry setting: Accounts Limit local account use of blank passwords to conso.
Version: 1.0.0
#>

# win-server-SECO-001: Accounts: Limit local account use of blank passwords to console logon only
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Accounts: Limit local account use of blank passwords to console logon only = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_001_Accounts_Limit_local_account_use_of_blank_passwords {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "LimitBlankPasswordUse"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
