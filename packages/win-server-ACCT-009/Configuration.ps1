<#
File: Configuration.ps1
Package: win-server-ACCT-009 - Reset account lockout counter after
Purpose: Enforces the local account/password/lockout policy setting: Reset account lockout counter after.
Version: 1.0.0
#>

# win-server-ACCT-009: Reset account lockout counter after
# This DSC configuration targets the local security policy setting:
#   Account Policies\Account Lockout Policy -> Reset account lockout counter after = 15 minutes
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_009_Reset_account_lockout_counter_after {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_009" {
            Name = "win-server-ACCT-009"
            Reset_account_lockout_counter_after = 15
        }
    }
}
