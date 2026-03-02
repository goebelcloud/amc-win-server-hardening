<#
File: Configuration.ps1
Package: win-server-ACCT-006 - Store passwords using reversible encryption
Purpose: Enforces the local account/password/lockout policy setting: Store passwords using reversible encryption.
Version: 1.0.0
#>

# win-server-ACCT-006: Store passwords using reversible encryption
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Store passwords using reversible encryption = Disabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_006_Store_passwords_using_reversible_encryption {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_006" {
            Name = "win-server-ACCT-006"
            Store_passwords_using_reversible_encryption = "Disabled"
        }
    }
}
