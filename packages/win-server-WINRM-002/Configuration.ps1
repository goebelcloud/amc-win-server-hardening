<#
File: Configuration.ps1
Package: win-server-WINRM-002 - Disallow Basic authentication
Purpose: Enforces a Windows security hardening registry setting: Disallow Basic authentication.
Version: 1.0.0
#>

# win-server-WINRM-002: Disallow Basic authentication
# This DSC configuration targets the local security policy setting:
#   Windows Components\Windows Remote Management (WinRM)\WinRM Service -> Disallow Basic authentication = Basic = Disabled (use Kerberos/cert)
# Expected impact: Low/Medium
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration WINRM_002_Disallow_Basic_authentication {
    Import-DscResource -ModuleName PSDscResources

    Node "localhost" {
        Registry "win-server-WINRM-002_1" {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth"
            ValueName = "Basic"
            ValueData = @("0")
            ValueType = "DWord"
        }

    }
}
