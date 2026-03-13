<#
File: Configuration.ps1
Package: win-server-SECO-010 - Interactive logon: Machine inactivity limit
Purpose: Enforces 'Interactive logon: Machine inactivity limit' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs to 900.
Version: 1.0.0
#>

# win-server-SECO-010: Interactive logon: Machine inactivity limit
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Interactive logon: Machine inactivity limit = 900 seconds (15 minutes)
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_010_Interactive_logon_Machine_inactivity_limit {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-010_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "InactivityTimeoutSecs"
            ValueData = @("900")
            ValueType = "DWord"
        }

    }
}
