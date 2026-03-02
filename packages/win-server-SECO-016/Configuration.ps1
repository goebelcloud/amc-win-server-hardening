<#
File: Configuration.ps1
Package: win-server-SECO-016 - Interactive logon: Machine inactivity limit
Purpose: Enforces 'Interactive logon: Machine inactivity limit' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\InactivityTimeoutSecs to 900.
Version: 1.0.0
#>

Configuration SECO_016_Interactive_logon_Machine_inactivity_limit {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-016_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "InactivityTimeoutSecs"
            ValueData = @("900")
            ValueType = "DWord"
        }

    }
}
