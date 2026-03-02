<#
.SYNOPSIS
  win-server-SECO-003 — Audit built-in Administrator account name (RID 500).

.DESCRIPTION
  Audits that the built-in local Administrator account (RID 500 / SID S-1-5-21-*-500) is NOT using the default name "Administrator".
  This package is AUDIT-ONLY (no remediation). It is intended for Azure Machine Configuration (Guest Configuration).

.VERSION
  1.0.0

.FILE
  Configuration.ps1
#>

# win-server-SECO-003: Audit: Built-in Administrator (RID 500) is not named 'Administrator'
# This DSC configuration targets the local security policy setting:
#   Security Options > Accounts -> Audit: Built-in Administrator (RID 500) is not named 'Administrator' = Compliant if Name != 'Administrator' (audit only; no remediation)
# Expected impact: Low (audit only)
#
# Implementation notes:
#   - This configuration is intended for standalone Windows Server VMs (no domain/GPO required).
#   - The DSC resource block below applies the setting locally (for example via security policy areas or registry-backed policy, depending on resource).

Configuration SECO_003_AuditAdminNotDefaultName {
  Import-DscResource -ModuleName "PSDscResources"

  Node "localhost" {
    Script AuditAdministratorAccountNotDefaultName {
      GetScript = {
        $admin = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE 'S-1-5-21-%-500'" | Select-Object -First 1
        if (-not $admin) {
          return @{ Result = "Built-in Administrator (RID 500) not found via Win32_UserAccount filter." }
        }
        return @{ Result = "Name=$($admin.Name); SID=$($admin.SID); Disabled=$($admin.Disabled)" }
      }

      TestScript = {
        $admin = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE 'S-1-5-21-%-500'" | Select-Object -First 1
        if (-not $admin) { return $false }
        # Compliant when the RID-500 account is NOT using the default name "Administrator"
        return ($admin.Name -ne "Administrator")
      }

      SetScript = {
        # Audit-only package: no remediation is performed.
      }
    }
  }
}
