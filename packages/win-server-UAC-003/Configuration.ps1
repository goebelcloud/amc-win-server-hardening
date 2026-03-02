<#
File: Configuration.ps1
Package: win-server-UAC-003 - User Account Control Behavior of the elevation prompt for ad
Purpose: Enforces a Windows security hardening registry setting: User Account Control Behavior of the elevation prompt for ad.
Version: 1.0.0
#>

# win-server-UAC-003: User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode = Prompt for consent on the secure desktop
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

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
