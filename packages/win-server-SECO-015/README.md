# win-server-SECO-015 — Audit: No local account uses the name 'Administrator'

- **Setting path:** `Local Users and Groups > Users`
- **Suggested value:** `No local account named 'Administrator' exists (audit only; no remediation)`
- **Default assignmentType:** `Audit`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/SECO-015/localhost.mof`
- `output/zip/SECO-015/win-server-SECO-015.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/SECO-015/deployIfNotExists.json`
- `output/policy/SECO-015/deployIfNotExists.enhanced.json`

### 3. Import policy
- Import exactly one of the two hydrated definitions.
- `deployIfNotExists.json` = standard / non-enhanced
- `deployIfNotExists.enhanced.json` = enhanced
- Do not use `*.portal.json`.

### 4. Create assignment
- `effect = DeployIfNotExists`
- `assignmentType = Audit`
- Enhanced only: `requiredUserAssignedIdentityResourceId`

### 5. Verify on the VM

#### Guest Configuration Assignment
Portal: check **VM > Guest configuration assignments**.

```bash
az resource list --resource-group <rg> --namespace Microsoft.Compute --resource-type "virtualMachines/providers/guestConfigurationAssignments" --query "[?contains(id, '/virtualMachines/<vmName>/')].[name, properties.guestConfiguration.name, properties.complianceStatus]" -o table
```

Expected:
- An assignment for `win-server-SECO-015` exists.
- `properties.guestConfiguration.name = win-server-SECO-015`
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
- recent entries for `win-server-SECO-015`
- no recurring persistent errors

#### Target setting
GUI: open `compmgmt.msc` and navigate to `Computer Management > Local Users and Groups > Users`.

```powershell
Get-LocalUser | Where-Object { $_.Name -ieq 'Administrator' } | Select-Object Name, Enabled, SID
```

Expected target value: No local account named 'Administrator' is found. If at least one result appears, the VM is non-compliant for this audit.
