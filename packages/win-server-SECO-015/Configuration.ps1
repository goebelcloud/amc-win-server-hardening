<#
.SYNOPSIS
  win-server-SECO-015 — Audit local account name 'Administrator'.

.DESCRIPTION
  Audits that no local account on the VM uses the well-known name "Administrator".
  This package is AUDIT-ONLY (no remediation). It is intended for Azure Machine Configuration (Guest Configuration).

.VERSION
  1.0.0

.FILE
  Configuration.ps1
#>

# win-server-SECO-015: Audit: No local account uses the name 'Administrator'
# This DSC configuration audits the local user list and is compliant only when
# no local account is named "Administrator".
# Expected impact: Low (audit only)

Configuration SECO_015_Audit_No_Local_Administrator_Name {
  Import-DscResource -ModuleName "PSDscResources"

  Node "localhost" {
    Script AuditNoLocalAdministratorName {
      GetScript = {
        $matches = @(Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=True AND Name='Administrator'" -ErrorAction SilentlyContinue)
        if ($matches.Count -eq 0) {
          return @{ Result = "No local account named Administrator found." }
        }

        $summary = $matches | Sort-Object SID | ForEach-Object {
          "Name=$($_.Name); SID=$($_.SID); Disabled=$($_.Disabled)"
        }

        return @{ Result = ($summary -join " | ") }
      }

      TestScript = {
        $matches = @(Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=True AND Name='Administrator'" -ErrorAction SilentlyContinue)
        return ($matches.Count -eq 0)
      }

      SetScript = {
        # Audit-only package: no remediation is performed.
      }
    }
  }
}
