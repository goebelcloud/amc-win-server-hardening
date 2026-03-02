<#
File: Configuration.ps1
Package: win-server-UAC-002 - User Account Control Switch to the secure desktop when promp
Purpose: Enforces a Windows security hardening registry setting: User Account Control Switch to the secure desktop when promp.
Version: 1.0.0
#>

Configuration UAC_002_User_Account_Control_Switch_to_the_secure_desktop_wh {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-UAC-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "PromptOnSecureDesktop"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
