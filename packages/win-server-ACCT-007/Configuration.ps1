<#
File: Configuration.ps1
Package: win-server-ACCT-007 - Account lockout threshold
Purpose: Enforces the local account/password/lockout policy setting: Account lockout threshold.
Version: 1.0.0
#>

Configuration ACCT_007_Account_lockout_threshold {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_007" {
            Name = "win-server-ACCT-007"
            Account_lockout_threshold = 10
        }
    }
}
