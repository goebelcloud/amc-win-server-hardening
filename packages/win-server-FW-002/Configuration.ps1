<#
File: Configuration.ps1
Package: win-server-FW-002 - Enable firewall logging
Purpose: Configures Windows Defender Firewall settings for: Enable firewall logging.
Version: 1.0.0
#>

# win-server-FW-002: Enable firewall logging
# This DSC configuration targets the local security policy setting:
#   Windows Defender Firewall with Advanced Security -> Enable firewall logging = Log dropped packets = Yes; Log successful connections = (Optional); Log size >= 16,384 KB
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration FW_002_Enable_firewall_logging {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script FW_002 {
            GetScript  = {
                return @{ Result = (Get-NetFirewallProfile | Select-Object Name, LogAllowed, LogBlocked, LogMaxSizeKilobytes, LogFileName | ConvertTo-Json -Compress) }
            }
            TestScript = {
                $profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
                if (-not $profiles) { return $false }
                foreach ($p in $profiles) {
                  if ($p.LogBlocked -ne $true) { return $false }
                  if ($p.LogAllowed -ne $false) { return $false }
                  if ($p.LogMaxSizeKilobytes -lt 16384) { return $false }
                }
                return $true
            }
            SetScript  = {
                Set-NetFirewallProfile -Profile Domain,Private,Public -LogBlocked $true -LogAllowed $false -LogMaxSizeKilobytes 16384 | Out-Null
            }
        }
    }
}
