<#
File: Configuration.ps1
Package: win-server-SECO-014 - Interactive logon: Do not display last user name
Purpose: Enforces 'Interactive logon: Do not display last user name' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLastUserName to 1.
Version: 1.0.0
#>

Configuration SECO_014_Interactive_logon_Do_not_display_last_user_name {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-014_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "DontDisplayLastUserName"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
