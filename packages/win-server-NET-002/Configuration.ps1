<#
File: Configuration.ps1
Package: win-server-NET-002 - Turn off AutoPlay AutoRun
Purpose: Enforces a Windows security hardening registry setting: Turn off AutoPlay AutoRun.
Version: 1.0.0
#>

# win-server-NET-002: Turn off AutoPlay / AutoRun
# This DSC configuration targets the local security policy setting:
#   Administrative Templates\Windows Components\AutoPlay Policies -> Turn off AutoPlay / AutoRun = Enabled (All drives)
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration NET_002_Turn_off_AutoPlay_AutoRun {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-NET-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            ValueName = "NoDriveTypeAutoRun"
            ValueData = @("255")
            ValueType = "DWord"
        }

    }
}
