<#
File: Configuration.ps1
Package: win-server-NET-001 - Disable SMBv1 (Client and Server)
Purpose: Hardens SMB configuration for: Disable SMBv1 Client and Server.
Version: 1.0.0
#>

# win-server-NET-001: Disable SMBv1 (Client and Server)
# This DSC configuration targets the local security policy setting:
#   SMB -> Disable SMBv1 (Client and Server) = Disable/remove SMBv1
# Expected impact: Medium (legacy SMB clients)
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration NET_001_Disable_SMBv1_Client_and_Server {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Script NET_001 {
            GetScript  = {
                $server = Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol
                $client = Get-SmbClientConfiguration | Select-Object EnableSMB1Protocol
                return @{ Result = @{
                  ServerEnableSMB1Protocol = $server.EnableSMB1Protocol
                  ClientEnableSMB1Protocol = $client.EnableSMB1Protocol
                } }
            }
            TestScript = {
                try {
                  $server = Get-SmbServerConfiguration -ErrorAction Stop
                  $client = Get-SmbClientConfiguration -ErrorAction Stop
                } catch {
                  return $false
                }
                if ($server.EnableSMB1Protocol -ne $false) { return $false }
                if ($client.EnableSMB1Protocol -ne $false) { return $false }
                return $true
            }
            SetScript  = {
                # Disable protocol at runtime
                try { Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force | Out-Null } catch { }
                try { Set-SmbClientConfiguration -EnableSMB1Protocol $false | Out-Null } catch { }

                # Attempt to remove/disable SMB1 feature if available (may require reboot)
                if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
                  $feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
                  if ($feature -and $feature.State -ne "Disabled") {
                    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
                  }
                }
                if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) {
                  $wf = Get-WindowsFeature -Name FS-SMB1 -ErrorAction SilentlyContinue
                  if ($wf -and $wf.Installed) {
                    Uninstall-WindowsFeature -Name FS-SMB1 -Restart:$false -ErrorAction SilentlyContinue | Out-Null
                  }
                }
            }
        }
    }
}
