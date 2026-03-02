<#
File: Configuration.ps1
Package: win-server-UAC-001 - User Account Control Run all administrators in Admin Approva
Purpose: Enforces a Windows security hardening registry setting: User Account Control Run all administrators in Admin Approva.
Version: 1.0.0
#>

Configuration UAC_001_User_Account_Control_Run_all_administrators_in_Admin {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-UAC-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "EnableLUA"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
