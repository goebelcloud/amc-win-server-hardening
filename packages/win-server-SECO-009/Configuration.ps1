<#
File: Configuration.ps1
Package: win-server-SECO-009 - Network security: LAN Manager authentication level
Purpose: Enforces 'Network security: LAN Manager authentication level' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel to 5.
Version: 1.0.0
#>

Configuration SECO_009_Network_security_LAN_Manager_authentication_level {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-009_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "LmCompatibilityLevel"
            ValueData = @("5")
            ValueType = "DWord"
        }

    }
}
