<#
File: Configuration.ps1
Package: win-server-AUD-002 - Audit Logon/Logoff (Success/Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Logon Logoff Success Failure.
Version: 1.0.0
#>

Configuration AUD_002_Audit_Logon_Logoff_Success_Failure {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script AUD_002 {
            GetScript  = {
                $output = (auditpol /get /category:"Logon/Logoff") | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (auditpol /get /category:"Logon/Logoff") | Out-String
                return ($output -match "Success and Failure")
            }
            SetScript  = {
                auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable | Out-Null
            }
        }
    }
}
