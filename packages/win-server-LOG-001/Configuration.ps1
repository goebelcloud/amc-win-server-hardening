<#
File: Configuration.ps1
Package: win-server-LOG-001 - PowerShell Script Block Logging
Purpose: Enforces a Windows security hardening registry setting: PowerShell Script Block Logging.
Version: 1.0.0
#>

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
