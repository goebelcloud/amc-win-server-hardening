<#
File: Configuration.ps1
Package: win-server-AUD-001 - Audit Account Logon (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Account Logon Success Failure.
Version: 1.0.0
#>

# win-server-AUD-001: Audit Account Logon (Success/Failure)
# This DSC configuration targets the local security policy setting:
#   Advanced Audit Policy Configuration -> Audit Account Logon (Success/Failure) = Enable Success and Failure
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration AUD_001_Audit_Account_Logon_Success_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_001 {
            GetScript  = {
                $output = (auditpol /get /category:"Account Logon") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"Account Logon") | Out-String
                return ($output -match "Success and Failure")
            }
            SetScript  = {
                auditpol /set /category:"Account Logon" /success:enable /failure:enable | Out-Null
            }
        }
    }
}
