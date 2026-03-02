<#
File: Configuration.ps1
Package: win-server-SECO-015 - Interactive logon: Do not require CTRL+ALT+DEL
Purpose: Enforces 'Interactive logon: Do not require CTRL+ALT+DEL' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD to 0.
Version: 1.0.0
#>

Configuration SECO_015_Interactive_logon_Do_not_require_CTRL_ALT_DEL {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-015_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "DisableCAD"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
