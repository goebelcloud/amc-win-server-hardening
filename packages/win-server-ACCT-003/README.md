# win-server-ACCT-003 — Minimum password age

- **Setting path:** `Account Policies\Password Policy`
- **Suggested value:** `1 day`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/ACCT-003/localhost.mof`
- `output/zip/ACCT-003/win-server-ACCT-003.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/ACCT-003/deployIfNotExists.json`
- `output/policy/ACCT-003/deployIfNotExists.enhanced.json`

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
- An assignment for `win-server-ACCT-003` exists.
- `properties.guestConfiguration.name = win-server-ACCT-003`
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
- recent entries for `win-server-ACCT-003`
- no recurring persistent errors

#### Target setting
GUI: open `secpol.msc` and navigate to `Account Policies > Password Policy`.

```powershell
          $tmp = Join-Path $env:TEMP 'secpol.inf'
secedit /export /cfg $tmp | Out-Null
Select-String -Path $tmp -Pattern '^MinimumPasswordAge\s*=\s*1$'
```

Expected target value: MinimumPasswordAge = 1 (1 day)
