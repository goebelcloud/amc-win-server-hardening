<#
File: Configuration.ps1
Package: win-server-AUD-005 - Audit Privilege Use (Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Privilege Use Failure.
Version: 1.0.0
#>

# win-server-AUD-005: Audit Privilege Use (Failure)
# This DSC configuration targets the local security policy setting:
#   Advanced Audit Policy Configuration -> Audit Privilege Use (Failure) = Enable Failure (and Success if required)
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration AUD_005_Audit_Privilege_Use_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_005 {
            GetScript  = {
                $output = (auditpol /get /category:"Privilege Use") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"Privilege Use") | Out-String
                return ($output -match "Failure")
            }
            SetScript  = {
                auditpol /set /category:"Privilege Use" /success:disable /failure:enable | Out-Null
            }
        }
    }
}
