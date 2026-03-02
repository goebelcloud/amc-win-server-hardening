<#
File: Configuration.ps1
Package: win-server-SECO-007 - Network access: Let Everyone permissions apply to anonymous users
Purpose: Enforces 'Network access: Let Everyone permissions apply to anonymous users' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\EveryoneIncludesAnonymous to 0.
Version: 1.0.0
#>

Configuration SECO_007_Network_access_Let_Everyone_permissions_apply_to_an {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-007_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "EveryoneIncludesAnonymous"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
