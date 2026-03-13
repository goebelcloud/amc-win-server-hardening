# win-server-DEF-001 — Real-time protection

- **Setting path:** `Windows Components\Microsoft Defender Antivirus`
- **Suggested value:** `Enabled (do not disable real-time monitoring)`
- **Default assignmentType:** `ApplyAndAutoCorrect`

## Checklist

### 1. Build
```powershell
pwsh ./build.ps1
```

Expected:
- `output/mof/DEF-001/localhost.mof`
- `output/zip/DEF-001/win-server-DEF-001.zip`

### 2. Hydrate
Upload the ZIP to Blob Storage. Then:
```powershell
pwsh ./hydrate-policy.ps1
```

Expected:
- `output/policy/DEF-001/deployIfNotExists.json`
- `output/policy/DEF-001/deployIfNotExists.enhanced.json`

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
- An assignment for `win-server-DEF-001` exists.
- `properties.guestConfiguration.name = win-server-DEF-001`
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
- recent entries for `win-server-DEF-001`
- no recurring persistent errors

#### Target setting
GUI: open `gpedit.msc` and navigate to `Windows Components > Microsoft Defender Antivirus`.

```powershell
Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' | Select-Object DisableRealtimeMonitoring
```

Expected target value: DisableRealtimeMonitoring = 0 (Enabled (do not disable real-time monitoring))
