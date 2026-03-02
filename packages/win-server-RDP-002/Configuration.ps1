<#
File: Configuration.ps1
Package: win-server-RDP-002 - Set client connection encryption level
Purpose: Enforces a Windows security hardening registry setting: Set client connection encryption level.
Version: 1.0.0
#>

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
