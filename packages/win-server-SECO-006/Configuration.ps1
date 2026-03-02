<#
File: Configuration.ps1
Package: win-server-SECO-006 - Network access: Do not allow anonymous enumeration of SAM accounts and shares
Purpose: Enforces 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\RestrictAnonymous to 1.
Version: 1.0.0
#>

Configuration SECO_006_Network_access_Do_not_allow_anonymous_enumeration_o {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-006_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "RestrictAnonymous"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
