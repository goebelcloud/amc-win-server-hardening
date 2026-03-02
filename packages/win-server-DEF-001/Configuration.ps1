<#
File: Configuration.ps1
Package: win-server-DEF-001 - Real time protection
Purpose: Enforces a Windows security hardening registry setting: Real time protection.
Version: 1.0.0
#>

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
