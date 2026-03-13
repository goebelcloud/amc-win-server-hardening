# win-server-DEF-002 — Cloud-delivered protection

- **Setting path:** `Windows Components\Microsoft Defender Antivirus`
- **Suggested value:** `Enabled`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/DEF-002/localhost.mof`
- `output/zip/DEF-002/win-server-DEF-002.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/DEF-002/deployIfNotExists.json`
- `output/policy/DEF-002/deployIfNotExists.enhanced.json`

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
- An assignment for `win-server-DEF-002` exists.
- `properties.guestConfiguration.name = win-server-DEF-002`
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
- recent entries for `win-server-DEF-002`
- no recurring persistent errors

#### Target setting
GUI: open `gpedit.msc` and navigate to `Windows Components > Microsoft Defender Antivirus`.

```powershell
Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' | Select-Object SpynetReporting, SubmitSamplesConsent
```

Expected target value: SpynetReporting = 2; SubmitSamplesConsent = 1 (Enabled)
