<#
File: Configuration.ps1
Package: win-server-SECO-017 - Shutdown: Allow system to be shut down without having to log on
Purpose: Enforces 'Shutdown: Allow system to be shut down without having to log on' by setting HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\ShutdownWithoutLogon to 0.
Version: 1.0.0
#>

Configuration SECO_017_Shutdown_Allow_system_to_be_shut_down_without_havin {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-017_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "ShutdownWithoutLogon"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
