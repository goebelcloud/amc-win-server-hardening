<#
File: Configuration.ps1
Package: win-server-SECO-011 - Network security: Minimum session security for NTLM SSP based (including secure RPC) servers
Purpose: Enforces 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' by setting HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\NtlmMinServerSec to 537395200.
Version: 1.0.0
#>

# win-server-SECO-011: Network security: Minimum session security for NTLM SSP based (including secure RPC) servers
# This DSC configuration targets the local security policy setting:
#   Local Policies\Security Options -> Network security: Minimum session security for NTLM SSP based (including secure RPC) servers = Require NTLMv2 session security; Require 128-bit encryption
# Expected impact: Low
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_011_Network_security_Minimum_session_security_for_NTLM_ {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-SECO-011_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"
            ValueName = "NtlmMinServerSec"
            ValueData = @("537395200")
            ValueType = "DWord"
        }

    }
}
