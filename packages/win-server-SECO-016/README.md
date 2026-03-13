# win-server-SECO-016 — Accounts: Rename guest account

- **Setting path:** `Local Policies\Security Options`
- **Suggested value:** `Rename to non-default (even if disabled)`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/SECO-016/localhost.mof`
- `output/zip/SECO-016/win-server-SECO-016.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/SECO-016/deployIfNotExists.json`
- `output/policy/SECO-016/deployIfNotExists.enhanced.json`

### 3. Import policy
- Import exactly one of the two hydrated definitions.
- `deployIfNotExists.json` = standard / non-enhanced
- `deployIfNotExists.enhanced.json` = enhanced
- Do not use `*.portal.json`.

### 4. Create assignment
- `effect = DeployIfNotExists`
- `assignmentType = ApplyAndAutoCorrect` (for pilot phases, use `Audit` or `ApplyAndMonitor` if needed)
- Enhanced only: `requiredUserAssignedIdentityResourceId`
- Package values from `policy-metadata.json` are injected during hydration: `GuestNewName`

### 5. Verify on the VM

#### Guest Configuration Assignment
Portal: check **VM > Guest configuration assignments**.

```bash
az resource list --resource-group <rg> --namespace Microsoft.Compute --resource-type "virtualMachines/providers/guestConfigurationAssignments" --query "[?contains(id, '/virtualMachines/<vmName>/')].[name, properties.guestConfiguration.name, properties.complianceStatus]" -o table
```

Expected:
- An assignment for `win-server-SECO-016` exists.
- `properties.guestConfiguration.name = win-server-SECO-016`
- With `ApplyAndMonitor` / `ApplyAndAutoCorrect`, the VM becomes `Compliant` after successful evaluation.
- With `Audit`, the VM is `NonCompliant` when the evaluated deviation is detected.

#### Agent / Guest Configuration log
```powershell
$logs = Get-ChildItem -Path 'C:\ProgramData\GuestConfig' -Recurse -File -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending
$logs | Select-Object -First 20 FullName, LastWriteTime
Get-Content -Path $logs[0].FullName -Tail 200
```

Expected:
- recent entries for `win-server-SECO-016`
- no recurring persistent errors

#### Target setting
GUI: open `compmgmt.msc` and navigate to `Computer Management > Local Users and Groups > Users`.

```powershell
Get-LocalUser | Where-Object { $_.SID.Value -match '-501$' } | Select-Object Name, Enabled, SID
```

Expected target value: RID 501 account name = LocalGuest.
