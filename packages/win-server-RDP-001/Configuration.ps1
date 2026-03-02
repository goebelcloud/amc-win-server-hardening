<#
File: Configuration.ps1
Package: win-server-RDP-001 - Require user authentication for remote connections by using 
Purpose: Enforces a Windows security hardening registry setting: Require user authentication for remote connections by using .
Version: 1.0.0
#>

# win-server-RDP-001: Require user authentication for remote connections by using Network Level Authentication
# This DSC configuration targets the local security policy setting:
#   Computer Configuration\Administrative Templates\Windows Components\Remote Desktop Services\Remote Desktop Session Host\Security -> Require user authentication for remote connections by using Network Level Authentication = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration RDP_001_Require_user_authentication_for_remote_connections_b {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-RDP-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
            ValueName = "UserAuthentication"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
