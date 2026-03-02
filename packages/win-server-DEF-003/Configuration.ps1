<#
File: Configuration.ps1
Package: win-server-DEF-003 - Potentially Unwanted Application PUA protection
Purpose: Enforces a Windows security hardening registry setting: Potentially Unwanted Application PUA protection.
Version: 1.0.0
#>

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
