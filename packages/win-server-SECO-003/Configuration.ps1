<#
File: Configuration.ps1
Package: win-server-SECO-003 - Network access: Do not allow anonymous enumeration of SAM accounts
Purpose: Enforces 'Network access: Do not allow anonymous enumeration of SAM accounts' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM to 1.
Version: 1.0.0
#>

# win-server-SECO-003: Network access: Do not allow anonymous enumeration of SAM accounts
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Network access: Do not allow anonymous enumeration of SAM accounts = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_003_Network_access_Do_not_allow_anonymous_enumeration_o {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-003_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "RestrictAnonymousSAM"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
