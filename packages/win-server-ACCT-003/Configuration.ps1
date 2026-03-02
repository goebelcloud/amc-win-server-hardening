<#
File: Configuration.ps1
Package: win-server-ACCT-003 - Minimum password age
Purpose: Enforces the local account/password/lockout policy setting: Minimum password age.
Version: 1.0.0
#>

Configuration ACCT_003_Minimum_password_age {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_003" {
            Name = "win-server-ACCT-003"
            Minimum_Password_Age = 1
        }
    }
}
