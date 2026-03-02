<#
File: Configuration.ps1
Package: win-server-ACCT-006 - Store passwords using reversible encryption
Purpose: Enforces the local account/password/lockout policy setting: Store passwords using reversible encryption.
Version: 1.0.0
#>

Configuration ACCT_006_Store_passwords_using_reversible_encryption {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_006" {
            Name = "win-server-ACCT-006"
            Store_passwords_using_reversible_encryption = "Disabled"
        }
    }
}
