<#
File: Configuration.ps1
Package: win-server-ACCT-002 - Maximum password age
Purpose: Enforces the local account/password/lockout policy setting: Maximum password age.
Version: 1.0.0
#>

Configuration ACCT_002_Maximum_password_age {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_002" {
            Name = "win-server-ACCT-002"
            Maximum_Password_Age = 60
        }
    }
}
