<#
File: Configuration.ps1
Package: win-server-UAC-003 - User Account Control Behavior of the elevation prompt for ad
Purpose: Enforces a Windows security hardening registry setting: User Account Control Behavior of the elevation prompt for ad.
Version: 1.0.0
#>

Configuration UAC_003_User_Account_Control_Behavior_of_the_elevation_promp {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-UAC-003_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "ConsentPromptBehaviorAdmin"
            ValueData = @("2")
            ValueType = "DWord"
        }

    }
}
