<#
File: Configuration.ps1
Package: win-server-RDP-002 - Set client connection encryption level
Purpose: Enforces a Windows security hardening registry setting: Set client connection encryption level.
Version: 1.0.0
#>

# win-server-RDP-002: Set client connection encryption level
# This DSC configuration targets the local security policy setting:
#   ...\Remote Desktop Session Host\Security -> Set client connection encryption level = High
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration RDP_002_Set_client_connection_encryption_level {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-RDP-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            ValueName = "MinEncryptionLevel"
            ValueData = @("3")
            ValueType = "DWord"
        }

    }
}
