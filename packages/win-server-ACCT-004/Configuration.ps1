<#
File: Configuration.ps1
Package: win-server-ACCT-004 - Minimum password length
Purpose: Enforces the local account/password/lockout policy setting: Minimum password length.
Version: 1.0.0
#>

# win-server-ACCT-004: Minimum password length
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Minimum password length = 14 characters
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_004_Minimum_password_length {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_004" {
            Name = "win-server-ACCT-004"
            Minimum_Password_Length = 14
        }
    }
}
