<#
File: Configuration.ps1
Package: win-server-ACCT-008 - Account lockout duration
Purpose: Enforces the local account/password/lockout policy setting: Account lockout duration.
Version: 1.0.0
#>

# win-server-ACCT-008: Account lockout duration
# This DSC configuration targets the local security policy setting:
#   Account Policies\Account Lockout Policy -> Account lockout duration = 15 minutes
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_008_Account_lockout_duration {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_008" {
            Name = "win-server-ACCT-008"
            Account_lockout_duration = 15
        }
    }
}
