# Test packages locally

## Goal
Before running the Azure test, you can validate an already built ZIP locally with the GuestConfiguration module.

## Test one package
Example path:

```powershell
Get-GuestConfigurationPackageComplianceStatus -Path ./output/zip/ACCT-001/win-server-ACCT-001.zip
```

## Test all packages
```powershell
pwsh ./scripts/test-all-packages.ps1
```

## Expected result
- ZIP file exists
- package structure is valid
- no parser or validation errors are reported by the GuestConfiguration module

## Note
Local package validation does not replace Azure-side verification. The functional check must still be completed on the target VM:
- assignment exists
- agent / Guest Configuration log is plausible
- Windows target setting matches the expected state
