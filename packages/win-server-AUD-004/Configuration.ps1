<#
File: Configuration.ps1
Package: win-server-AUD-004 - Audit Policy Change (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Policy Change Success Failure.
Version: 1.0.0
#>

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
