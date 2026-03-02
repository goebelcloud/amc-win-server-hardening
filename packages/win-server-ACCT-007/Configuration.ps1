<#
File: Configuration.ps1
Package: win-server-ACCT-007 - Account lockout threshold
Purpose: Enforces the local account/password/lockout policy setting: Account lockout threshold.
Version: 1.0.0
#>

# win-server-ACCT-007: Account lockout threshold
# This DSC configuration targets the local security policy setting:
#   Account Policies\Account Lockout Policy -> Account lockout threshold = 10 invalid logon attempts (WS2025 baseline uses 3; test before lowering)
# Expected impact: Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_007_Account_lockout_threshold {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_007" {
            Name = "win-server-ACCT-007"
            Account_lockout_threshold = 10
        }
    }
}
