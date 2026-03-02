<#
File: Configuration.ps1
Package: win-server-AUD-006 - Audit System (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit System Success Failure.
Version: 1.0.0
#>

Configuration AUD_006_Audit_System_Success_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_006 {
            GetScript  = {
                $output = (auditpol /get /category:"System") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"System") | Out-String
                return ($output -match "Success and Failure")
            }
            SetScript  = {
                auditpol /set /category:"System" /success:enable /failure:enable | Out-Null
            }
        }
    }
}
