<#
File: Configuration.ps1
Package: win-server-AUD-004 - Audit Policy Change (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Policy Change Success Failure.
Version: 1.0.0
#>

# win-server-AUD-004: Audit Policy Change (Success/Failure)
# This DSC configuration targets the local security policy setting:
#   Advanced Audit Policy Configuration -> Audit Policy Change (Success/Failure) = Enable Success and Failure
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration AUD_004_Audit_Policy_Change_Success_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_004 {
            GetScript  = {
                $output = (auditpol /get /category:"Policy Change") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"Policy Change") | Out-String
                return ($output -match "Success and Failure")
            }
            SetScript  = {
                auditpol /set /category:"Policy Change" /success:enable /failure:enable | Out-Null
            }
        }
    }
}
