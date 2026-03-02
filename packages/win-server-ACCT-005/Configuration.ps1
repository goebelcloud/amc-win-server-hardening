<#
File: Configuration.ps1
Package: win-server-ACCT-005 - Password must meet complexity requirements
Purpose: Enforces the local account/password/lockout policy setting: Password must meet complexity requirements.
Version: 1.0.0
#>

# win-server-ACCT-005: Password must meet complexity requirements
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Password must meet complexity requirements = Enabled
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_005_Password_must_meet_complexity_requirements {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_005" {
            Name = "win-server-ACCT-005"
            Password_must_meet_complexity_requirements = "Enabled"
        }
    }
}
