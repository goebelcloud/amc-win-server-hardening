<#
File: Configuration.ps1
Package: win-server-LSA-001 - Enable LSA protection RunAsPPL
Purpose: Enforces a Windows security hardening registry setting: Enable LSA protection RunAsPPL.
Version: 1.0.0
#>

# win-server-LSA-001: Enable LSA protection (RunAsPPL)
# This DSC configuration targets the local security policy setting:
#   System\Local Security Authority -> Enable LSA protection (RunAsPPL) = Enabled (Audit first if possible)
# Expected impact: Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration LSA_001_Enable_LSA_protection_RunAsPPL {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-LSA-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa"
            ValueName = "RunAsPPL"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
