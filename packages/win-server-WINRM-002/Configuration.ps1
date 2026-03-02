<#
File: Configuration.ps1
Package: win-server-WINRM-002 - Disallow Basic authentication
Purpose: Enforces a Windows security hardening registry setting: Disallow Basic authentication.
Version: 1.0.0
#>

Configuration WINRM_002_Disallow_Basic_authentication {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-WINRM-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth"
            ValueName = "Basic"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
