<#
File: Configuration.ps1
Package: win-server-DEF-003 - Potentially Unwanted Application PUA protection
Purpose: Enforces a Windows security hardening registry setting: Potentially Unwanted Application PUA protection.
Version: 1.0.0
#>

# win-server-DEF-003: Potentially Unwanted Application (PUA) protection
# This DSC configuration targets the local security policy setting:
#   Windows Components\Microsoft Defender Antivirus -> Potentially Unwanted Application (PUA) protection = Enabled (Block)
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration DEF_003_Potentially_Unwanted_Application_PUA_protection {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-DEF-003_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender"
            ValueName = "PUAProtection"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
