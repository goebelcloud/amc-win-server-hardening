<#
File: Configuration.ps1
Package: win-server-ACCT-002 - Maximum password age
Purpose: Enforces the local account/password/lockout policy setting: Maximum password age.
Version: 1.0.0
#>

# win-server-ACCT-002: Maximum password age
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Maximum password age = 60 days (or org standard 60–90)
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_002_Maximum_password_age {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_002" {
            Name = "win-server-ACCT-002"
            Maximum_Password_Age = 60
        }
    }
}
