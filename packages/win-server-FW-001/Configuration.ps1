<#
File: Configuration.ps1
Package: win-server-FW-001 - Enable firewall for all profiles
Purpose: Configures Windows Defender Firewall settings for: Enable firewall for all profiles.
Version: 1.0.0
#>

# win-server-FW-001: Enable firewall for all profiles
# This DSC configuration targets the local security policy setting:
#   Windows Defender Firewall with Advanced Security -> Enable firewall for all profiles = Enabled (Domain/Private/Public) + default inbound = Block
# Expected impact: Medium (depends on inbound rules)
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration FW_001_Enable_firewall_for_all_profiles {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script FW_001 {
            GetScript  = {
                return @{ Result = (Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction | ConvertTo-Json -Compress) }
            }
            TestScript = {
                $profiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
                if (-not $profiles) { return $false }
                return ((($profiles | Where-Object { $_.Enabled -ne $true }).Count -eq 0) -and (($profiles | Where-Object { $_.DefaultInboundAction -ne 'Block' }).Count -eq 0))
            }
            SetScript  = {
                Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled $true -DefaultInboundAction Block | Out-Null
            }
        }
    }
}
