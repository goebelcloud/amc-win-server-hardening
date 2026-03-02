<#
File: Configuration.ps1
Package: win-server-WINRM-001 - Allow unencrypted traffic
Purpose: Enforces a Windows security hardening registry setting: Allow unencrypted traffic.
Version: 1.0.0
#>

# win-server-WINRM-001: Allow unencrypted traffic
# This DSC configuration targets the local security policy setting:
#   Windows Components\Windows Remote Management (WinRM)\WinRM Service -> Allow unencrypted traffic = Disabled
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration WINRM_001_Allow_unencrypted_traffic {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-WINRM-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service"
            ValueName = "AllowUnencryptedTraffic"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
