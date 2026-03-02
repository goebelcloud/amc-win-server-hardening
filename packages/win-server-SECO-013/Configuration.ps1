<#
File: Configuration.ps1
Package: win-server-SECO-013 - Microsoft network server: Digitally sign communications (always)
Purpose: Enforces 'Microsoft network server: Digitally sign communications (always)' via DSC (registry-backed security option).
Version: 1.0.0
#>

# win-server-SECO-013: Microsoft network server: Digitally sign communications (always)
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Microsoft network server: Digitally sign communications (always) = Enabled (SMB signing required for inbound SMB server traffic)
# Expected impact: Medium (legacy/non-signing SMB clients)
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_013_Microsoft_network_server_Digitally_sign_communicati {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script SECO_012 {
            GetScript  = {
                $cfg = Get-SmbServerConfiguration | Select-Object RequireSecuritySignature, EnableSecuritySignature
                return @{ Result = ($cfg | ConvertTo-Json -Compress) }
            }
            TestScript = {
                $cfg = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
                if (-not $cfg) { return $false }
                return ($cfg.RequireSecuritySignature -eq $true)
            }
            SetScript  = {
                Set-SmbServerConfiguration -RequireSecuritySignature $true -Force | Out-Null
            }
        }
    }
}
