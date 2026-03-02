<#
File: Configuration.ps1
Package: win-server-NET-002 - Turn off AutoPlay AutoRun
Purpose: Enforces a Windows security hardening registry setting: Turn off AutoPlay AutoRun.
Version: 1.0.0
#>

Configuration NET_002_Turn_off_AutoPlay_AutoRun {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-NET-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            ValueName = "NoDriveTypeAutoRun"
            ValueData = @("255")
            ValueType = "DWord"
        }

    }
}
