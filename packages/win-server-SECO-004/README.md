# win-server-SECO-004 — Accounts: Rename guest account

**Version:** 1.0.0  
**Purpose:** Rename the built-in **Guest** account (RID 501) to a non-default name via Azure Machine Configuration (DSC).  
- **Setting path:** `Local Policies\Security Options`
- **Setting:** `Accounts: Rename guest account`
- **Suggested value:** `Rename to non-default (even if disabled)`
- **Impact:** `Low`

## Why this matters
Reduces discovery/targeting of the well-known 'Guest' username.

## What this package changes
- Identifies the built-in local **Guest** account using RID **501** (SID `S-1-5-21-*-501`).
- Renames it to the value from a Machine Configuration parameter file:
  - `C:\ProgramData\MachineConfiguration\win-server-SECO-004\GuestNewName.txt`
- Default value (if no parameter override is supplied): `LocalGuest`

## How to evaluate the setting (built-in OS tools)

**1) Find the Guest account by RID 501**
```powershell
Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND SID LIKE 'S-1-5-21-%-501'" |
  Select-Object Name, SID, Disabled
```

**2) Confirm the desired name (parameter file)**
```powershell
Get-Content "C:\ProgramData\MachineConfiguration\win-server-SECO-004\GuestNewName.txt" -ErrorAction SilentlyContinue
```

## Manual remediation (built-in OS tools)
Rename the Guest account using local tools (validate operational dependencies first):
```powershell
$user = Get-LocalUser | Where-Object SID -like "S-1-5-21-*-501"
Rename-LocalUser -Name $user.Name -NewName "LocalGuest"
```

## Machine Configuration prerequisites (expected on target VMs)
These packages assume the VM is prepared for Azure Machine Configuration:
- **System-assigned managed identity enabled**  
- **Machine Configuration extension** installed: Publisher `Microsoft.GuestConfiguration`, Type `ConfigurationforWindows`, Name `AzurePolicyforWindows`  
- **Required user-assigned managed identity (UAMI)** attached to the VM (used via `contentManagedIdentity`)

## DSC configuration
- Configuration name: `SECO_004_Accounts_Rename_guest_account`
- Source file: `Configuration.ps1`

## Build this package (standalone)
From this package directory:
```powershell
.\build.ps1
```

## Hydrate the enhanced policy JSON for this package
After uploading the built ZIP and setting `ContentUriBase` + `RequiredUamiResourceId` in `packages/machine-configuration.config.json`:
```powershell
.\hydrate-policy.ps1
```

## Policy files included
- `policy/deployIfNotExists.json` — baseline policy template
- `policy/deployIfNotExists.enhanced.sample.json` — enhanced sample with prerequisite checks + UAMI requirement + Windows Server offer/SKU scope

## CIS / benchmarks reference
WS2016:
CIS Microsoft Windows Server 2016 Benchmark v4.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".
CIS Microsoft Windows Server 2016 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".
WS2019:
CIS Microsoft Windows Server 2019 STIG Benchmark v4.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".
WS2022:
CIS Microsoft Windows Server 2022 Benchmark v4.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".
CIS Microsoft Windows Server 2022 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".
WS2025:
CIS Microsoft Windows Server 2025 Stand-alone v1.0.0 — Topic area: Security Options; search for: "Accounts: Rename guest account".

**CIS chapter IDs:** TBD (see CIS PDFs / CIS STIG docs)

## Sources
- MS baseline mapping (Windows Server 2016/2019/2022):
  Azure Policy guest configuration baseline for Windows (Server 2016/2019/2022) — search for: Accounts: Rename guest account
- MS baseline mapping (Windows Server 2025):
  Azure Policy guest configuration baseline for Windows Server 2025 — search for: Accounts: Rename guest account
- Machine Configuration package authoring (`New-GuestConfigurationPackage`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package
- Machine Configuration policy authoring (`New-GuestConfigurationPolicy`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition
