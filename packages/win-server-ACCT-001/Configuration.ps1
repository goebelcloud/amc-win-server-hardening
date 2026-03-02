<#
File: Configuration.ps1
Package: win-server-ACCT-001 - Enforce password history
Purpose: Enforces the local account/password/lockout policy setting: Enforce password history.
Version: 1.0.0
#>

Configuration ACCT_001_Enforce_password_history {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_001" {
            Name = "win-server-ACCT-001"
            Enforce_password_history = 24
        }
    }
}
