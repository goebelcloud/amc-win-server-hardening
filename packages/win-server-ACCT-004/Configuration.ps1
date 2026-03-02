<#
File: Configuration.ps1
Package: win-server-ACCT-004 - Minimum password length
Purpose: Enforces the local account/password/lockout policy setting: Minimum password length.
Version: 1.0.0
#>

Configuration ACCT_004_Minimum_password_length {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_004" {
            Name = "win-server-ACCT-004"
            Minimum_Password_Length = 14
        }
    }
}
