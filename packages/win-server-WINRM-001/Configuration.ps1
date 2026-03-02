<#
File: Configuration.ps1
Package: win-server-WINRM-001 - Allow unencrypted traffic
Purpose: Enforces a Windows security hardening registry setting: Allow unencrypted traffic.
Version: 1.0.0
#>

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
