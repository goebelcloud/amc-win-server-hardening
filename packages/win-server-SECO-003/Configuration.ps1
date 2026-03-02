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
