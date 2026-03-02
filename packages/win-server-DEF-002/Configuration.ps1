<#
File: Configuration.ps1
Package: win-server-DEF-002 - Cloud delivered protection
Purpose: Enforces a Windows security hardening registry setting: Cloud delivered protection.
Version: 1.0.0
#>

# win-server-DEF-002: Cloud-delivered protection
# This DSC configuration targets the local security policy setting:
#   Windows Components\Microsoft Defender Antivirus -> Cloud-delivered protection = Enabled
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration DEF_002_Cloud_delivered_protection {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-DEF-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
            ValueName = "SpynetReporting"
            ValueData = @("2")
            ValueType = "DWord"
        }

        Registry "win-server-DEF-002_2" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
            ValueName = "SubmitSamplesConsent"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
