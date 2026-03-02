<#
File: Configuration.ps1
Package: win-server-SECO-012 - Microsoft network client: Digitally sign communications (always)
Purpose: Enforces 'Microsoft network client: Digitally sign communications (always)' via DSC (registry-backed security option).
Version: 1.0.0
#>

Configuration SECO_012_Microsoft_network_client_Digitally_sign_communicati {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script SECO_011 {
            GetScript  = {
                $cfg = Get-SmbClientConfiguration | Select-Object RequireSecuritySignature, EnableSecuritySignature
                return @{ Result = ($cfg | ConvertTo-Json -Compress) }
            }
            TestScript = {
                $cfg = Get-SmbClientConfiguration -ErrorAction SilentlyContinue
                if (-not $cfg) { return $false }
                return ($cfg.RequireSecuritySignature -eq $true)
            }
            SetScript  = {
                Set-SmbClientConfiguration -RequireSecuritySignature $true -Force | Out-Null
            }
        }
    }
}
