<#
File: Configuration.ps1
Package: win-server-DEF-001 - Real time protection
Purpose: Enforces a Windows security hardening registry setting: Real time protection.
Version: 1.0.0
#>

# win-server-DEF-001: Real-time protection
# This DSC configuration targets the local security policy setting:
#   Windows Components\Microsoft Defender Antivirus -> Real-time protection = Enabled (do not disable real-time monitoring)
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration DEF_001_Real_time_protection {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-DEF-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
            ValueName = "DisableRealtimeMonitoring"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
