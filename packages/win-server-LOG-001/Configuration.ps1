<#
File: Configuration.ps1
Package: win-server-LOG-001 - PowerShell Script Block Logging
Purpose: Enforces a Windows security hardening registry setting: PowerShell Script Block Logging.
Version: 1.0.0
#>

# win-server-LOG-001: PowerShell Script Block Logging
# This DSC configuration targets the local security policy setting:
#   Windows Components\Windows PowerShell -> PowerShell Script Block Logging = Enabled
# Expected impact: Low/Medium (log volume)
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration LOG_001_PowerShell_Script_Block_Logging {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-LOG-001_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
            ValueName = "EnableScriptBlockLogging"
            ValueData = @("1")
            ValueType = "DWord"
        }

    }
}
