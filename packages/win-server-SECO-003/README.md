# win-server-SECO-003 — Audit built-in Administrator account name (RID 500)

## What this package does
This package **audits only** whether the built-in local Administrator account (RID 500 / SID `S-1-5-21-*-500`) is **NOT** named `Administrator`.

- **Compliant**: RID-500 account name is not `Administrator`
- **Non-compliant**: RID-500 account name is `Administrator` or the RID-500 account cannot be located

This package does **not** rename any accounts.

## How to evaluate on the VM (built-in tools)

### PowerShell (recommended)
```powershell
Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE 'S-1-5-21-%-500'" |
  Select-Object Name, SID, Disabled
```

On Windows Server 2012+ you can also use:
```powershell
Get-LocalUser | Where-Object SID -like "S-1-5-21-*-500" | Select-Object Name, SID, Enabled
```

### Expected result
- `Name` should **not** be `Administrator`.

## Build this package standalone
1. Ensure required authoring modules are installed on the build machine:
   ```powershell
   ..\..\authoring-workstation\install-required-modules.ps1 -Scope CurrentUser
   ```
2. Build MOF + package ZIP:
   ```powershell
   .\build.ps1
   ```

Artifacts are written to the configured output folders (see `packages/machine-configuration.config.json`).

## Build via batch script
From repo root:
```powershell
.\scripts\build-all.ps1
```

## Hydrate the enhanced policy JSON for this package
After the ZIP is uploaded to your package storage and `ContentUriBase` + `RequiredUamiResourceId` are set:
```powershell
.\hydrate-policy.ps1
```

The hydrated policy JSON is written to the configured policy output folder.
