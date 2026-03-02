<#
File: Configuration.ps1
Package: win-server-RDP-003 - Do not allow passwords to be saved
Purpose: Enforces a Windows security hardening registry setting: Do not allow passwords to be saved.
Version: 1.0.0
#>

Configuration RDP_003_Do_not_allow_passwords_to_be_saved {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-RDP-003_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "DisablePasswordSaving"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
