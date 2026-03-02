<#
File: Configuration.ps1
Package: win-server-SECO-008 - Network security: Do not store LAN Manager hash value on next password change
Purpose: Enforces 'Network security: Do not store LAN Manager hash value on next password change' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\NoLMHash to 1.
Version: 1.0.0
#>

Configuration SECO_008_Network_security_Do_not_store_LAN_Manager_hash_valu {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-008_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "NoLMHash"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
