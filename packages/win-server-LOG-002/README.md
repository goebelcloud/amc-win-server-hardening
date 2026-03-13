# win-server-LOG-002 — Increase Security log maximum size

- **Setting path:** `Event Logs`
- **Suggested value:** `>= 196,608 KB (192 MB) (tune for environment)`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/LOG-002/localhost.mof`
- `output/zip/LOG-002/win-server-LOG-002.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/LOG-002/deployIfNotExists.json`
- `output/policy/LOG-002/deployIfNotExists.enhanced.json`

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
- An assignment for `win-server-LOG-002` exists.
- `properties.guestConfiguration.name = win-server-LOG-002`
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
- recent entries for `win-server-LOG-002`
- no recurring persistent errors

#### Target setting
GUI: open `eventvwr.msc` and navigate to `Windows Logs > Security > Properties`.

```powershell
wevtutil gl Security
```

Expected target value: Output contains maxSize >= 201326592 bytes (>= 196608 KB / 192 MB).
