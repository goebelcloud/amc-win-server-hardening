<#
File: Configuration.ps1
Package: win-server-LOG-002 - Increase Security log maximum size
Purpose: Configures Windows Event Log settings for: Increase Security log maximum size.
Version: 1.0.0
#>

Configuration LOG_002_Increase_Security_log_maximum_size {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script LOG_002 {
            GetScript  = {
                $output = (wevtutil gl Security) | Out-String
                return @{ Result = $output }
            }
            TestScript = {
                $output = (wevtutil gl Security) | Out-String
                $match = [regex]::Match($output, "maxSize:\s*(\d+)")
                if (-not $match.Success) { return $false }
                $current = [int64]$match.Groups[1].Value
                return ($current -ge 201326592)
            }
            SetScript  = {
                wevtutil sl Security /ms:201326592 | Out-Null
            }
        }
    }
}
