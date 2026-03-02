<#
File: Configuration.ps1
Package: win-server-AUD-005 - Audit Privilege Use (Failure)
Purpose: Enforces Windows Advanced Audit Policy for: Audit Privilege Use Failure.
Version: 1.0.0
#>

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
