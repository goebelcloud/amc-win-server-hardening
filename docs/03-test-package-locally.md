# 03 — Test a package locally (no Azure)

This guide validates that a built package ZIP is structurally correct and contains required content.

It does **not** require Azure Machine Configuration or Azure Policy.

## 1. Build the package first

Example:

```powershell
cd .\packages\win-server-ACCT-001
.\build.ps1
```

## 2. Validate the ZIP locally

From repo root:

```powershell
.\scripts\test-all-packages.ps1
```

This uses:

`Get-GuestConfigurationPackageComplianceStatus`

to check the ZIP content.

## 3. Validate a single ZIP manually

Locate the ZIP (based on `OutputPaths.PackageZipOutputRoot`):

Example path:
`output\zip\win-server-ACCT-001\win-server-ACCT-001.zip`

Then run:

```powershell
Get-GuestConfigurationPackageComplianceStatus -Path .\output\zip\win-server-ACCT-001\win-server-ACCT-001.zip |
  Select-Object PackageName, Version, Status, Reasons | Format-List
```

## Troubleshooting

- If the cmdlet is missing: install modules via `authoring-workstation\install-required-modules.ps1`.
- If the ZIP is missing: run the relevant `build.ps1` again (or `scripts\build-all.ps1`).
