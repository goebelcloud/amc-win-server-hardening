<#
File: Configuration.ps1
Package: win-server-UAC-001 - User Account Control Run all administrators in Admin Approva
Purpose: Enforces a Windows security hardening registry setting: User Account Control Run all administrators in Admin Approva.
Version: 1.0.0
#>

# win-server-UAC-001: User Account Control: Run all administrators in Admin Approval Mode
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> User Account Control: Run all administrators in Admin Approval Mode = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration UAC_001_User_Account_Control_Run_all_administrators_in_Admin {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-UAC-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            ValueName = "EnableLUA"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
