<#
File: Configuration.ps1
Package: win-server-RDP-003 - Do not allow passwords to be saved
Purpose: Enforces a Windows security hardening registry setting: Do not allow passwords to be saved.
Version: 1.0.0
#>

# win-server-RDP-003: Do not allow passwords to be saved
# This DSC configuration targets the local security policy setting:
#   ...\Remote Desktop Session Host\Security -> Do not allow passwords to be saved = Enabled
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration RDP_003_Do_not_allow_passwords_to_be_saved {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-RDP-003_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
            ValueName = "DisablePasswordSaving"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
