# win-server-SECO-006 — Network access: Do not allow anonymous enumeration of SAM accounts and shares

**Version:** 1.0.0  
**Purpose:** Enforce the following setting via Azure Machine Configuration (DSC).  
- **Setting path:** `Local Policies\Security Options`
- **Setting:** `Network access: Do not allow anonymous enumeration of SAM accounts and shares`
- **Suggested value:** `Enabled`
- **Impact:** `Low`

## Why this matters
Further reduces anonymous discovery of users and shares (reconnaissance).

## What this package changes
- Registry: `HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\RestrictAnonymous` (DWord) = `1`

## How to verify the setting is applied (built-in OS tools)

### GUI verification
1. Press **Win+R**, run `secpol.msc` (Local Security Policy).
2. Navigate to: **Local Policies > Security Options**.
3. Open **Network access: Do not allow anonymous enumeration of SAM accounts and shares** and confirm it is set to **Enabled**.

### Command-line verification
**Registry check (PowerShell / reg.exe)**
```cmd
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous
```
Expected: `RestrictAnonymous` (DWord) = `1`.

## Machine Configuration prerequisites (expected on target VMs)
These packages assume the VM is prepared for Azure Machine Configuration:
- **System-assigned managed identity enabled**  
- **Machine Configuration extension** installed: Publisher `Microsoft.GuestConfiguration`, Type `ConfigurationforWindows`, Name `AzurePolicyforWindows`  
- **Required user-assigned managed identity (UAMI)** attached to the VM (used via `contentManagedIdentity`)

## DSC configuration
- Configuration name: `SECO_006_Network_access_Do_not_allow_anonymous_enumeration_o`
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
CIS Microsoft Windows Server 2016 Benchmark v4.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".
CIS Microsoft Windows Server 2016 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".
WS2019:
CIS Microsoft Windows Server 2019 STIG Benchmark v4.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".
WS2022:
CIS Microsoft Windows Server 2022 Benchmark v4.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".
CIS Microsoft Windows Server 2022 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".
WS2025:
CIS Microsoft Windows Server 2025 Stand-alone v1.0.0 — Topic area: Security Options; search for: "Network access: Do not allow anonymous enumeration of SAM accounts and shares".

**CIS chapter IDs:** TBD (see CIS PDFs / CIS STIG docs)

## Sources
- MS baseline mapping (Windows Server 2016/2019/2022):
  Azure Policy guest configuration baseline for Windows (Server 2016/2019/2022) — search for: Network access: Do not allow anonymous enumeration of SAM accounts and shares
- MS baseline mapping (Windows Server 2025):
  Azure Policy guest configuration baseline for Windows Server 2025 — search for: Network access: Do not allow anonymous enumeration of SAM accounts and shares
- Machine Configuration package authoring (`New-GuestConfigurationPackage`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package
- Machine Configuration policy authoring (`New-GuestConfigurationPolicy`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition
