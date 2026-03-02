<#
File: Configuration.ps1
Package: win-server-DEF-002 - Cloud delivered protection
Purpose: Enforces a Windows security hardening registry setting: Cloud delivered protection.
Version: 1.0.0
#>

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
