<#
File: Configuration.ps1
Package: win-server-SECO-015 - Interactive logon: Do not require CTRL+ALT+DEL
Purpose: Enforces 'Interactive logon: Do not require CTRL+ALT+DEL' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD to 0.
Version: 1.0.0
#>

# win-server-SECO-015: Interactive logon: Do not require CTRL+ALT+DEL
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Interactive logon: Do not require CTRL+ALT+DEL = Disabled (require CTRL+ALT+DEL)
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_015_Interactive_logon_Do_not_require_CTRL_ALT_DEL {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-015_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "DisableCAD"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
