# win-server-AUD-005 — Audit Privilege Use (Failure)

- **Setting path:** `Advanced Audit Policy Configuration`
- **Suggested value:** `Enable Failure (and Success if required)`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/AUD-005/localhost.mof`
- `output/zip/AUD-005/win-server-AUD-005.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/AUD-005/deployIfNotExists.json`
- `output/policy/AUD-005/deployIfNotExists.enhanced.json`

### 3. Import policy
- Import exactly one of the two hydrated definitions.
- `deployIfNotExists.json` = standard / non-enhanced
- `deployIfNotExists.enhanced.json` = enhanced
- Do not use `*.portal.json`.

### 4. Create assignment
- `effect = DeployIfNotExists`
- `assignmentType = ApplyAndAutoCorrect` (for pilot phases, use `Audit` or `ApplyAndMonitor` if needed)
- Enhanced only: `requiredUserAssignedIdentityResourceId`

### 5. Verify on the VM

#### Guest Configuration Assignment
Portal: check **VM > Guest configuration assignments**.

```bash
az resource list --resource-group <rg> --namespace Microsoft.Compute --resource-type "virtualMachines/providers/guestConfigurationAssignments" --query "[?contains(id, '/virtualMachines/<vmName>/')].[name, properties.guestConfiguration.name, properties.complianceStatus]" -o table
```

Expected:
- An assignment for `win-server-AUD-005` exists.
- `properties.guestConfiguration.name = win-server-AUD-005`
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
- recent entries for `win-server-AUD-005`
- no recurring persistent errors

#### Target setting
GUI: open `secpol.msc` and navigate to `Advanced Audit Policy Configuration`.

```powershell
auditpol /get /category:"Privilege Use"
```

Expected target value: Current setting shows Failure enabled.
