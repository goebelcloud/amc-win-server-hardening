<#
File: Configuration.ps1
Package: win-server-ACCT-009 - Reset account lockout counter after
Purpose: Enforces the local account/password/lockout policy setting: Reset account lockout counter after.
Version: 1.0.0
#>

Configuration ACCT_009_Reset_account_lockout_counter_after {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_009" {
            Name = "win-server-ACCT-009"
            Reset_account_lockout_counter_after = 15
        }
    }
}
