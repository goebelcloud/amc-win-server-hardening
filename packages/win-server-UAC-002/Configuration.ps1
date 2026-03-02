<#
File: Configuration.ps1
Package: win-server-UAC-002 - User Account Control Switch to the secure desktop when promp
Purpose: Enforces a Windows security hardening registry setting: User Account Control Switch to the secure desktop when promp.
Version: 1.0.0
#>

# win-server-UAC-002: User Account Control: Switch to the secure desktop when prompting for elevation
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> User Account Control: Switch to the secure desktop when prompting for elevation = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration UAC_002_User_Account_Control_Switch_to_the_secure_desktop_wh {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-UAC-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "PromptOnSecureDesktop"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
