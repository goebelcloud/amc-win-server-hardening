<#
File: Configuration.ps1
Package: win-server-ACCT-001 - Enforce password history
Purpose: Enforces the local account/password/lockout policy setting: Enforce password history.
Version: 1.0.0
#>

# win-server-ACCT-001: Enforce password history
# This DSC configuration targets the local security policy setting:
#   Account Policies\Password Policy -> Enforce password history = 24 passwords remembered
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration ACCT_001_Enforce_password_history {
    Import-DscResource -ModuleName @{ ModuleName = "SecurityPolicyDsc"; ModuleVersion = "2.10.0.0" }

    Node "localhost" {
        AccountPolicy "ACCT_001" {
            Name = "win-server-ACCT-001"
            Enforce_password_history = 24
        }
    }
}
