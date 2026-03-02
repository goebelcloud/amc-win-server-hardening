<#
File: Configuration.ps1
Package: win-server-SECO-010 - Network security: Minimum session security for NTLM SSP based (including secure RPC) clients
Purpose: Enforces 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\NtlmMinClientSec to 537395200.
Version: 1.0.0
#>

Configuration SECO_010_Network_security_Minimum_session_security_for_NTLM_ {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-010_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
            ValueName = "NtlmMinClientSec"
            ValueData = @("537395200")
            ValueType = "DWord"
        }

    }
}
