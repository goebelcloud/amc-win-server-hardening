<#
File: Configuration.ps1
Package: win-server-SECO-007 - Network security: LAN Manager authentication level
Purpose: Enforces 'Network security: LAN Manager authentication level' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel to 5.
Version: 1.0.0
#>

# win-server-SECO-007: Network security: LAN Manager authentication level
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Network security: LAN Manager authentication level = Send NTLMv2 response only. Refuse LM & NTLM
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_007_Network_security_LAN_Manager_authentication_level {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-007_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "LmCompatibilityLevel"
            ValueData = @("5")
            ValueType = "DWord"
        }

    }
}
