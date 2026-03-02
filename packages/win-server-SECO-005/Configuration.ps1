<#
File: Configuration.ps1
Package: win-server-SECO-005 - Network access: Do not allow anonymous enumeration of SAM accounts
Purpose: Enforces 'Network access: Do not allow anonymous enumeration of SAM accounts' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM to 1.
Version: 1.0.0
#>

Configuration SECO_005_Network_access_Do_not_allow_anonymous_enumeration_o {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-005_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "RestrictAnonymousSAM"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
