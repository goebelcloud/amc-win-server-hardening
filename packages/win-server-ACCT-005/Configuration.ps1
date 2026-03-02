<#
File: Configuration.ps1
Package: win-server-ACCT-005 - Password must meet complexity requirements
Purpose: Enforces the local account/password/lockout policy setting: Password must meet complexity requirements.
Version: 1.0.0
#>

Configuration ACCT_005_Password_must_meet_complexity_requirements {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_005" {
            Name = "win-server-ACCT-005"
            Password_must_meet_complexity_requirements = "Enabled"
        }
    }
}
