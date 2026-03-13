<#
File: Configuration.ps1
Package: win-server-SECO-006 - Network security: Do not store LAN Manager hash value on next password change
Purpose: Enforces 'Network security: Do not store LAN Manager hash value on next password change' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\NoLMHash to 1.
Version: 1.0.0
#>

# win-server-SECO-006: Network security: Do not store LAN Manager hash value on next password change
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Network security: Do not store LAN Manager hash value on next password change = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_006_Network_security_Do_not_store_LAN_Manager_hash_valu {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-006_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "NoLMHash"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
