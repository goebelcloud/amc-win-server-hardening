<#
File: Configuration.ps1
Package: win-server-AUD-003 - Audit Account Management (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Account Management Success Failure.
Version: 1.0.0
#>

Configuration AUD_003_Audit_Account_Management_Success_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_003 {
            GetScript  = {
                $output = (auditpol /get /category:"Account Management") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"Account Management") | Out-String
                return ($output -match "Success and Failure")
            }
            SetScript  = {
                auditpol /set /category:"Account Management" /success:enable /failure:enable | Out-Null
            }
        }
    }
}
