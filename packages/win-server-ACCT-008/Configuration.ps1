<#
File: Configuration.ps1
Package: win-server-ACCT-008 - Account lockout duration
Purpose: Enforces the local account/password/lockout policy setting: Account lockout duration.
Version: 1.0.0
#>

Configuration ACCT_008_Account_lockout_duration {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_008" {
            Name = "win-server-ACCT-008"
            Account_lockout_duration = 15
        }
    }
}
