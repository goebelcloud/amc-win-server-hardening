<#
File: Configuration.ps1
Package: win-server-SECO-005 - Network access: Let Everyone permissions apply to anonymous users
Purpose: Enforces 'Network access: Let Everyone permissions apply to anonymous users' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\EveryoneIncludesAnonymous to 0.
Version: 1.0.0
#>

# win-server-SECO-005: Network access: Let Everyone permissions apply to anonymous users
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Network access: Let Everyone permissions apply to anonymous users = Disabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_005_Network_access_Let_Everyone_permissions_apply_to_an {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-005_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "EveryoneIncludesAnonymous"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
