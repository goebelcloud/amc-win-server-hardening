<#
File: Configuration.ps1
Package: win-server-ACCT-003 - Minimum password age
Purpose: Enforces the local account/password/lockout policy setting: Minimum password age.
Version: 1.0.0
#>

# win-server-ACCT-003: Minimum password age
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Minimum password age = 1 day
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_003_Minimum_password_age {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_003" {
            Name = "win-server-ACCT-003"
            Minimum_Password_Age = 1
        }
    }
}
