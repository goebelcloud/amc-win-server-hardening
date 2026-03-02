<#
File: Configuration.ps1
Package: win-server-SECO-014 - Interactive logon: Do not display last user name
Purpose: Enforces 'Interactive logon: Do not display last user name' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLastUserName to 1.
Version: 1.0.0
#>

# win-server-SECO-014: Interactive logon: Do not display last user name
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Interactive logon: Do not display last user name = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_014_Interactive_logon_Do_not_display_last_user_name {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-014_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "DontDisplayLastUserName"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
